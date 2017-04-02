import PackageDescription

let package = Package(
    name: "todo-list",
    dependencies:[
    .Package(url:"https://github.com/IBM-Swift/Kitura.git",majorVersion:1),
    .Package(url:"https://github.com/IBM-Swift/HeliumLogger.git",majorVersion:1),
    .Package(url:"https://github.com/vapor/sqlite",majorVersion:1)
    ]
)
