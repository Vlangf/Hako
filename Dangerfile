# Apply SwiftLint
swiftlint.config_file = '.swiftlint.yml'
swiftlint.binary_path = "./Pods/SwiftLint/swiftlint"
swiftlint.lint_files inline_mode: true

# Don't let testing shortcuts get into master
fail("fdescribe left in tests") if `grep -r fdescribe HakoTests/`.length > 1
fail("fit left in tests") if `grep -rI "fit(" HakoTests/`.length > 1
fail("fcontext left in tests") if `grep -rI "fcontext(" HakoTests/`.length > 1
