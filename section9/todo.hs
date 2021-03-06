import           Control.Exception
import           Data.List
import           System.Directory
import           System.Environment
import           System.IO

dispatch :: String -> [String] -> IO ()
dispatch "add"    = add
dispatch "view"   = view
dispatch "remove" = remove
dispatch "bump"   = bump
dispatch command  = doesntExist command

main = do
  (command:argList) <- getArgs
  dispatch command argList

add :: [String] -> IO ()
add [fileName, todoItem] = appendFile fileName (todoItem ++ "\n")
add _ = putStrLn "the add command takes exactly two argments"

view :: [String] -> IO ()
view [fileName] = do
  contents <- readFile fileName
  let todoTasks = lines contents
      numberedTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
  putStr $ unlines numberedTasks
view [] = putStrLn "the view command takes a fileName"

remove :: [String] -> IO ()
remove [fileName, numberString] = do
  contents <- readFile fileName
  let todoTasks = lines contents
      numberedTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
  putStrLn "these area your to-do items:"
  mapM_ putStrLn numberedTasks
  let number = read numberString
      newTodoItems = unlines $ delete (todoTasks !! number) todoTasks
  bracketOnError (openTempFile "." "temp")
    (\(tempName, tempHandle) -> do
      hClose tempHandle
      removeFile tempName)

    (\(tempName, tempHandle) ->do
      hPutStr tempHandle newTodoItems
      hClose tempHandle
      removeFile fileName
      renameFile tempName fileName
    )
remove _ = putStrLn "the remove command takes exactly two argments"

bump :: [String] -> IO ()
bump [fileName, numberString] = do
  contents <- readFile fileName
  let todoTasks = lines contents
      numberedTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
  putStrLn "these are your to-do items:"
  mapM_ putStrLn numberedTasks

  let number = read numberString
      newTodoItems = unlines $ (todoTasks !! number) : delete (todoTasks !! number) todoTasks

  bracketOnError (openTempFile "." "temp")
    (\(tempName, tempHandle) -> do
      hClose tempHandle
      removeFile tempName)

    (\(tempName, tempHandle) ->do
      hPutStr tempHandle newTodoItems
      hClose tempHandle
      removeFile fileName
      renameFile tempName fileName
    )
bump _ = putStrLn "the bump command takes exactly two argments"

doesntExist :: String -> [String] -> IO ()
doesntExist command _ =
  putStrLn $ "the " ++ command ++ " comand does not exist"
