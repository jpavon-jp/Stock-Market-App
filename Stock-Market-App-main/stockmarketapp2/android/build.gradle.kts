// android/build.gradle.kts  (== root‐level build script)
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // <- put the Google-services classpath here
        classpath("com.google.gms:google-services:4.3.15")
    }
}

// --- the rest of your file can stay exactly as you had it ---
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // repositories {} here is optional; you already have them above
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
