let argumentError = FlutterError(code: "E_ARG", message: "Invalid Arguments", details: nil)
let containerError = FlutterError(
  code: "E_CTR",
  message: "Invalid containerId, or user is not signed in, or user disabled iCloud permission",
  details: nil)
let fileNotFoundError = FlutterError(
  code: "E_FNF", message: "The file does not exist", details: nil)
