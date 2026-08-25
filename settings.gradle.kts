// Root settings file for Gradle
rootProject.name = "IdrakLiseyi"

// Include the actual Android project
include(":android")
project(":android").projectDir = file("android")
