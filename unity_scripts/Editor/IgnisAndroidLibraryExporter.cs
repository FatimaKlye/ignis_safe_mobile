using System;
using System.IO;
using UnityEditor;
using UnityEngine;

public static class IgnisAndroidLibraryExporter
{
    private static readonly string[] Scenes =
    {
        "Assets/Scenes/Bootstrap.unity",
        "Assets/Scenes/FireExtinguisher_PASS.unity",
        "Assets/Scenes/House_FireEscape.unity",
        "Assets/Scenes/Electrical Fire Safety.unity",
        "Assets/Scenes/Kitchen Fire Safety.unity",
        "Assets/Scenes/Building_Fire.unity",
    };

    public static void Export()
    {
        try
        {
            string outputPath = ReadArgument("-ignisExportPath");
            if (string.IsNullOrWhiteSpace(outputPath))
                throw new ArgumentException("-ignisExportPath is required.");

            outputPath = Path.GetFullPath(outputPath);
            if (Directory.Exists(outputPath) &&
                Directory.GetFileSystemEntries(outputPath).Length > 0)
            {
                throw new IOException(
                    "The Unity export directory must be empty: " + outputPath
                );
            }

            Directory.CreateDirectory(outputPath);
            EditorUserBuildSettings.exportAsGoogleAndroidProject = true;
            EditorUserBuildSettings.androidBuildSystem = AndroidBuildSystem.Gradle;

            BuildPlayerOptions options = new BuildPlayerOptions
            {
                scenes = Scenes,
                locationPathName = outputPath,
                target = BuildTarget.Android,
                options = BuildOptions.None,
            };

            var report = BuildPipeline.BuildPlayer(options);
            var summary = report.summary;
            Debug.Log(
                "[IgnisAndroidLibraryExporter] Result=" + summary.result +
                " size=" + summary.totalSize +
                " duration=" + summary.totalTime
            );

            if (summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
                EditorApplication.Exit(1);
        }
        catch (Exception error)
        {
            Debug.LogException(error);
            EditorApplication.Exit(1);
        }
    }

    private static string ReadArgument(string name)
    {
        string[] args = Environment.GetCommandLineArgs();
        for (int index = 0; index < args.Length - 1; index++)
        {
            if (string.Equals(args[index], name, StringComparison.Ordinal))
                return args[index + 1];
        }

        return null;
    }
}
