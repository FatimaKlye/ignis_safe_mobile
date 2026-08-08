using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEngine;

public static class IgnisMobileMemoryOptimizer
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

    private const int MobileTextureLimit = 1024;
    private const int MobileUiTextureLimit = 2048;
    private const int MobileHdrTextureLimit = 1024;

    public static void Audit()
    {
        string[] dependencies = GetBuildDependencies();
        List<TextureRecord> textures = GetTextureRecords(dependencies);
        List<string> models = GetImporterPaths<ModelImporter>(dependencies);
        List<string> audio = GetImporterPaths<AudioImporter>(dependencies);

        Debug.Log(
            "[IgnisMobileMemoryOptimizer] AUDIT " +
            "dependencies=" + dependencies.Length +
            " textures=" + textures.Count +
            " textureSourceMB=" + Math.Round(textures.Sum(item => item.sourceBytes) / 1048576d, 1) +
            " sourceTexturesAbove" + MobileTextureLimit + "=" +
            textures.Count(item => item.maxDimension > MobileTextureLimit) +
            " streamingTextures=" + textures.Count(item => item.streamingMipmaps) +
            " androidOverrides=" + textures.Count(item => item.androidOverride) +
            " readableTextures=" + textures.Count(item => item.isReadable) +
            " models=" + models.Count +
            " audio=" + audio.Count
        );

        foreach (TextureRecord item in textures
                     .OrderByDescending(record => record.estimatedPixels)
                     .Take(30))
        {
            Debug.Log(
                "[IgnisMobileMemoryOptimizer] TEXTURE " +
                item.width + "x" + item.height +
                " sourceMB=" + Math.Round(item.sourceBytes / 1048576d, 2) +
                " maxSize=" + item.maxTextureSize +
                " android=" + item.androidFormat +
                " streaming=" + item.streamingMipmaps +
                " path=" + item.path
            );
        }
    }

    public static void Optimize()
    {
        string[] dependencies = GetBuildDependencies();
        int textureChanges = OptimizeTextures(dependencies);
        int modelChanges = OptimizeModels(dependencies);
        int audioChanges = OptimizeAudio(dependencies);

        PlayerSettings.stripEngineCode = true;
        PlayerSettings.gcIncremental = true;
        PlayerSettings.SetManagedStrippingLevel(
            NamedBuildTarget.Android,
            ManagedStrippingLevel.Medium
        );

        QualitySettings.streamingMipmapsActive = true;
        QualitySettings.streamingMipmapsMemoryBudget = 128f;
        QualitySettings.streamingMipmapsMaxLevelReduction = 3;
        QualitySettings.streamingMipmapsAddAllCameras = true;
        if (QualitySettings.antiAliasing > 2)
            QualitySettings.antiAliasing = 2;
        if (QualitySettings.shadowDistance > 50f)
            QualitySettings.shadowDistance = 50f;
        if (
            (int)QualitySettings.shadowResolution >
            (int)ShadowResolution.Medium
        )
            QualitySettings.shadowResolution = ShadowResolution.Medium;

        AssetDatabase.SaveAssets();
        Debug.Log(
            "[IgnisMobileMemoryOptimizer] OPTIMIZED " +
            "textures=" + textureChanges +
            " models=" + modelChanges +
            " audio=" + audioChanges +
            " streamingBudgetMB=" + QualitySettings.streamingMipmapsMemoryBudget +
            " antiAliasing=" + QualitySettings.antiAliasing +
            " shadowDistance=" + QualitySettings.shadowDistance +
            " shadowResolution=" + QualitySettings.shadowResolution
        );
    }

    private static int OptimizeTextures(string[] dependencies)
    {
        int changes = 0;
        foreach (string path in dependencies)
        {
            TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
            if (importer == null) continue;

            bool changed = false;
            bool isHdr = string.Equals(
                Path.GetExtension(path),
                ".exr",
                StringComparison.OrdinalIgnoreCase
            );
            bool isUiTexture =
                importer.textureType == TextureImporterType.Sprite ||
                importer.textureType == TextureImporterType.GUI ||
                importer.textureType == TextureImporterType.Cursor;
            int limit = isHdr
                ? MobileHdrTextureLimit
                : (isUiTexture ? MobileUiTextureLimit : MobileTextureLimit);

            if (importer.maxTextureSize > limit)
            {
                importer.maxTextureSize = limit;
                changed = true;
            }

            if (importer.textureCompression != TextureImporterCompression.CompressedHQ)
            {
                importer.textureCompression = TextureImporterCompression.CompressedHQ;
                changed = true;
            }

            bool canStream =
                importer.mipmapEnabled &&
                importer.textureShape == TextureImporterShape.Texture2D &&
                importer.textureType != TextureImporterType.Sprite &&
                importer.textureType != TextureImporterType.GUI &&
                importer.textureType != TextureImporterType.Cursor;
            if (canStream && !importer.streamingMipmaps)
            {
                importer.streamingMipmaps = true;
                changed = true;
            }

            TextureImporterPlatformSettings android =
                importer.GetPlatformTextureSettings("Android");
            if (android.maxTextureSize != limit)
            {
                android.maxTextureSize = limit;
                changed = true;
            }
            if (!isHdr)
            {
                if (!android.overridden)
                {
                    android.overridden = true;
                    changed = true;
                }
                if (android.format != TextureImporterFormat.ASTC_6x6)
                {
                    android.format = TextureImporterFormat.ASTC_6x6;
                    changed = true;
                }
                if (android.compressionQuality != 65)
                {
                    android.compressionQuality = 65;
                    changed = true;
                }
            }

            if (!changed) continue;
            importer.SetPlatformTextureSettings(android);
            importer.SaveAndReimport();
            changes++;
        }

        return changes;
    }

    private static int OptimizeModels(string[] dependencies)
    {
        int changes = 0;
        foreach (string path in dependencies)
        {
            ModelImporter importer = AssetImporter.GetAtPath(path) as ModelImporter;
            if (importer == null) continue;

            bool changed = false;
            if (importer.meshCompression == ModelImporterMeshCompression.Off)
            {
                importer.meshCompression = ModelImporterMeshCompression.Low;
                changed = true;
            }
            if (!importer.optimizeMeshPolygons)
            {
                importer.optimizeMeshPolygons = true;
                changed = true;
            }
            if (!importer.optimizeMeshVertices)
            {
                importer.optimizeMeshVertices = true;
                changed = true;
            }

            if (!changed) continue;
            importer.SaveAndReimport();
            changes++;
        }

        return changes;
    }

    private static int OptimizeAudio(string[] dependencies)
    {
        int changes = 0;
        foreach (string path in dependencies)
        {
            AudioImporter importer = AssetImporter.GetAtPath(path) as AudioImporter;
            if (importer == null) continue;

            AudioImporterSampleSettings settings = importer.defaultSampleSettings;
            bool changed = false;
            if (settings.compressionFormat != AudioCompressionFormat.Vorbis)
            {
                settings.compressionFormat = AudioCompressionFormat.Vorbis;
                changed = true;
            }
            if (settings.quality > 0.65f)
            {
                settings.quality = 0.65f;
                changed = true;
            }
            if (settings.sampleRateSetting != AudioSampleRateSetting.OptimizeSampleRate)
            {
                settings.sampleRateSetting = AudioSampleRateSetting.OptimizeSampleRate;
                changed = true;
            }
            if (!importer.loadInBackground)
            {
                importer.loadInBackground = true;
                changed = true;
            }

            if (!changed) continue;
            importer.defaultSampleSettings = settings;
            importer.SaveAndReimport();
            changes++;
        }

        return changes;
    }

    private static string[] GetBuildDependencies()
    {
        string[] missing = Scenes.Where(scene => !File.Exists(scene)).ToArray();
        if (missing.Length > 0)
            throw new FileNotFoundException(
                "Missing build scenes: " + string.Join(", ", missing)
            );

        return AssetDatabase.GetDependencies(Scenes, true)
            .Where(path => path.StartsWith("Assets/", StringComparison.Ordinal))
            .Distinct()
            .ToArray();
    }

    private static List<string> GetImporterPaths<T>(string[] dependencies)
        where T : AssetImporter
    {
        return dependencies
            .Where(path => AssetImporter.GetAtPath(path) is T)
            .ToList();
    }

    private static List<TextureRecord> GetTextureRecords(string[] dependencies)
    {
        var records = new List<TextureRecord>();
        foreach (string path in dependencies)
        {
            TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
            if (importer == null) continue;

            importer.GetSourceTextureWidthAndHeight(out int width, out int height);
            TextureImporterPlatformSettings android =
                importer.GetPlatformTextureSettings("Android");
            long sourceBytes = File.Exists(path) ? new FileInfo(path).Length : 0L;

            records.Add(
                new TextureRecord
                {
                    path = path,
                    width = width,
                    height = height,
                    estimatedPixels = (long)width * height,
                    sourceBytes = sourceBytes,
                    maxDimension = Math.Max(width, height),
                    maxTextureSize = importer.maxTextureSize,
                    streamingMipmaps = importer.streamingMipmaps,
                    isReadable = importer.isReadable,
                    androidOverride = android.overridden,
                    androidFormat = android.format.ToString(),
                }
            );
        }

        return records;
    }

    private sealed class TextureRecord
    {
        public string path;
        public int width;
        public int height;
        public long estimatedPixels;
        public long sourceBytes;
        public int maxDimension;
        public int maxTextureSize;
        public bool streamingMipmaps;
        public bool isReadable;
        public bool androidOverride;
        public string androidFormat;
    }
}
