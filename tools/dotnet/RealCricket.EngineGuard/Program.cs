using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;

namespace RealCricket.EngineGuard
{
    /// <summary>
    /// Fails when a compiled assembly depends on Unity.
    /// Architecture contract (docs/02-architecture.md): RealCricket.Core must be
    /// usable by a plain .NET build machine with no Unity installed.
    /// </summary>
    internal static class Program
    {
        private const string Usage =
            "usage: RealCricket.EngineGuard [--forbid A,B] [--verbose] <assembly.dll> [more.dll...]\n" +
            "  --forbid   comma-separated forbidden prefixes (default: UnityEngine,UnityEditor)\n" +
            "  --verbose  list every assembly/type reference that was inspected\n" +
            "exit codes: 0 = clean, 1 = violation or unreadable input, 2 = bad arguments";

        private static readonly string[] DefaultForbidden = { "UnityEngine", "UnityEditor" };

        private static int Main(string[] args)
        {
            var targets = new List<string>();
            var forbidden = DefaultForbidden;
            var verbose = false;

            for (var i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "-h":
                    case "--help":
                        Console.WriteLine(Usage);
                        return 0;

                    case "--forbid":
                        if (i + 1 >= args.Length)
                        {
                            Console.Error.WriteLine("RealCricket.EngineGuard: --forbid needs a value");
                            return 2;
                        }

                        forbidden = args[++i].Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                        break;

                    case "--verbose":
                        verbose = true;
                        break;

                    default:
                        if (args[i].StartsWith("-", StringComparison.Ordinal))
                        {
                            Console.Error.WriteLine($"RealCricket.EngineGuard: unknown option '{args[i]}'");
                            return 2;
                        }

                        targets.Add(args[i]);
                        break;
                }
            }

            if (targets.Count == 0)
            {
                Console.Error.WriteLine(Usage);
                return 2;
            }

            var violations = new List<string>();
            var referencesChecked = 0;
            var typesChecked = 0;

            foreach (var target in targets)
            {
                Inspect(target, forbidden, verbose, violations, ref referencesChecked, ref typesChecked);
            }

            if (violations.Count > 0)
            {
                foreach (var violation in violations)
                {
                    Console.Error.WriteLine($"RealCricket.EngineGuard: VIOLATION — {violation}");
                }

                Console.Error.WriteLine(
                    $"check-engine-independence: FAILED — {violations.Count} forbidden reference(s) in {targets.Count} assembly/assemblies");
                return 1;
            }

            Console.WriteLine(
                $"check-engine-independence: OK — {targets.Count} assembly/assemblies clean " +
                $"({referencesChecked} assembly reference(s), {typesChecked} type reference(s)/definition(s) inspected)");
            return 0;
        }

        private static void Inspect(
            string path,
            string[] forbidden,
            bool verbose,
            List<string> violations,
            ref int referencesChecked,
            ref int typesChecked)
        {
            if (!File.Exists(path))
            {
                violations.Add($"{path}: file not found");
                return;
            }

            using var stream = File.OpenRead(path);
            using var peReader = new PEReader(stream);

            if (!peReader.HasMetadata)
            {
                violations.Add($"{path}: not a .NET assembly (no CLI metadata)");
                return;
            }

            var reader = peReader.GetMetadataReader();
            var assemblyName = reader.IsAssembly
                ? reader.GetString(reader.GetAssemblyDefinition().Name)
                : Path.GetFileNameWithoutExtension(path);

            if (verbose)
            {
                Console.WriteLine($"{assemblyName}: inspecting {path}");
            }

            foreach (var handle in reader.AssemblyReferences)
            {
                var reference = reader.GetAssemblyReference(handle);
                var name = reader.GetString(reference.Name);
                referencesChecked++;

                if (verbose)
                {
                    Console.WriteLine($"  assembly ref  {name}");
                }

                if (IsForbidden(name, forbidden))
                {
                    violations.Add($"{assemblyName} references assembly '{name}'");
                }
            }

            foreach (var handle in reader.TypeReferences)
            {
                var reference = reader.GetTypeReference(handle);
                var ns = reader.GetString(reference.Namespace);
                var name = reader.GetString(reference.Name);
                typesChecked++;

                if (verbose)
                {
                    Console.WriteLine($"  type ref      {(ns.Length == 0 ? name : ns + "." + name)}");
                }

                if (IsForbidden(ns, forbidden) || IsForbidden(name, forbidden))
                {
                    violations.Add($"{assemblyName} references type '{ns}.{name}'");
                }
            }

            foreach (var handle in reader.TypeDefinitions)
            {
                var definition = reader.GetTypeDefinition(handle);
                var ns = reader.GetString(definition.Namespace);
                var name = reader.GetString(definition.Name);
                typesChecked++;

                if (IsForbidden(ns, forbidden) || IsForbidden(name, forbidden))
                {
                    violations.Add($"{assemblyName} defines type '{ns}.{name}'");
                }
            }
        }

        /// <summary>
        /// True when <paramref name="candidate"/> is a forbidden root name or lives
        /// under it, e.g. "UnityEngine", "UnityEngine.CoreModule",
        /// "UnityEngine.Rendering". Matching is ordinal and segment-aware, so a
        /// name such as "UnityEngineX" is not a false positive.
        /// </summary>
        private static bool IsForbidden(string candidate, string[] forbidden)
        {
            if (candidate.Length == 0)
            {
                return false;
            }

            foreach (var prefix in forbidden)
            {
                if (candidate.Equals(prefix, StringComparison.Ordinal) ||
                    candidate.StartsWith(prefix + ".", StringComparison.Ordinal))
                {
                    return true;
                }
            }

            return false;
        }
    }
}
