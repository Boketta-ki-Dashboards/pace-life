#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project without third-party tooling."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
objects = {}
def uid(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def q(value):
    return json.dumps(value)
def add(name, content):
    objects[uid(name)] = content
    return uid(name)
def refs(values):
    return '(' + ', '.join(values) + (',' if values else '') + ')'
def group(name, children, path=None):
    return add(name, 'isa = PBXGroup; children = ' + refs(children) + '; ' + (f'path = {q(path)}; ' if path else '') + 'sourceTree = "<group>";')

def source_group(folder, target):
    files, builds = [], []
    for path in sorted((ROOT / folder).rglob('*.swift')):
        relative = path.relative_to(ROOT / folder).as_posix()
        file = add(str(path.relative_to(ROOT)), f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(relative)}; sourceTree = "<group>";')
        files.append(file)
        builds.append(add('build:' + str(path.relative_to(ROOT)), f'isa = PBXBuildFile; fileRef = {file};'))
    return group('group:'+folder, files, folder), add('sources:'+target, f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs(builds)}; runOnlyForDeploymentPostprocessing = 0;')

app_group, app_sources = source_group('PaceLife', 'app')
test_group, test_sources = source_group('PaceLifeUITests', 'tests')
app_product = add('app-product', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = PaceLife.app; sourceTree = BUILT_PRODUCTS_DIR;')
test_product = add('test-product', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = PaceLifeUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
products = group('products', [app_product, test_product]); root_group = group('root-group', [app_group, test_group, products])
package = add('local-package', 'isa = XCLocalSwiftPackageReference; relativePath = Packages/PaceLifeCore;')
product_dep = add('package-product', f'isa = XCSwiftPackageProductDependency; package = {package}; productName = PaceLifeCore;')
framework = add('core-framework', f'isa = PBXBuildFile; productRef = {product_dep};')
frameworks = add('frameworks', f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({framework},); runOnlyForDeploymentPostprocessing = 0;')
resources = add('resources', 'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')

def configs(name, settings):
    ids = []
    for kind in ['Debug','Release']:
        options = dict(settings)
        # Match Xcode's normal Debug/Release policy and Swift package targets.
        # Do not force or exclude any architecture: the destination selects it.
        options['ONLY_ACTIVE_ARCH'] = 'YES' if kind == 'Debug' else 'NO'
        options['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if kind == 'Debug' else '-O'
        options['DEBUG_INFORMATION_FORMAT'] = 'dwarf' if kind == 'Debug' else 'dwarf-with-dsym'
        if kind == 'Debug':
            options['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) DEBUG'
            options['ENABLE_TESTABILITY'] = 'YES'
        body = ' '.join(f'{key} = {q(value)};' for key, value in options.items())
        ids.append(add(name+kind, f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {kind};'))
    return add(name+'-configs', f'isa = XCConfigurationList; buildConfigurations = {refs(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

project_configs = configs('project', {'SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_VERSION':'6.0','CLANG_ENABLE_MODULES':'YES','SWIFT_STRICT_CONCURRENCY':'complete','ENABLE_USER_SCRIPT_SANDBOXING':'YES'})
app_configs = configs('app', {'PRODUCT_BUNDLE_IDENTIFIER':'com.boketta.pacelife','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_KEY_CFBundleDisplayName':'Pace Life','INFOPLIST_KEY_LSApplicationCategoryType':'public.app-category.lifestyle','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','TARGETED_DEVICE_FAMILY':'1','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','SUPPORTS_MACCATALYST':'NO','CODE_SIGN_STYLE':'Automatic','CURRENT_PROJECT_VERSION':'1','MARKETING_VERSION':'0.1.0'})
test_configs = configs('tests', {'PRODUCT_BUNDLE_IDENTIFIER':'com.boketta.pacelife.uitests','PRODUCT_NAME':'$(TARGET_NAME)','GENERATE_INFOPLIST_FILE':'YES','TARGETED_DEVICE_FAMILY':'1','TEST_TARGET_NAME':'PaceLife','CODE_SIGN_STYLE':'Automatic'})
proxy = add('test-proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("app")}; remoteInfo = PaceLife;')
dependency = add('test-dependency', f'isa = PBXTargetDependency; target = {uid("app")}; targetProxy = {proxy};')
app = add('app', f'isa = PBXNativeTarget; buildConfigurationList = {app_configs}; buildPhases = ({app_sources}, {frameworks}, {resources},); buildRules = (); dependencies = (); name = PaceLife; packageProductDependencies = ({product_dep},); productName = PaceLife; productReference = {app_product}; productType = "com.apple.product-type.application";')
tests = add('tests', f'isa = PBXNativeTarget; buildConfigurationList = {test_configs}; buildPhases = ({test_sources},); buildRules = (); dependencies = ({dependency},); name = PaceLifeUITests; productName = PaceLifeUITests; productReference = {test_product}; productType = "com.apple.product-type.bundle.ui-testing";')
project = add('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; TargetAttributes = {{ {app} = {{ CreatedOnToolsVersion = 16.0; }}; {tests} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {app}; }}; }}; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = de; hasScannedForEncodings = 0; knownRegions = (de,en,ru,Base,); mainGroup = {root_group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; packageReferences = ({package},); targets = ({app},{tests},);')
output = '// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n'
output += '\n'.join(f'\t\t{key} = {{ {value} }};' for key,value in sorted(objects.items()))
output += f'\n\t}};\n\trootObject = {project};\n}}\n'
(ROOT/'PaceLife.xcodeproj/project.pbxproj').write_text(output)
def build_ref(target, name, product):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="{product}" BlueprintName="{name}" ReferencedContainer="container:PaceLife.xcodeproj"/>'
app_ref = build_ref(app,'PaceLife','PaceLife.app'); test_ref=build_ref(tests,'PaceLifeUITests','PaceLifeUITests.xctest')
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
(ROOT/'PaceLife.xcodeproj/xcshareddata/xcschemes/PaceLife.xcscheme').write_text(scheme)
print('Generated PaceLife.xcodeproj with', len(objects), 'objects')
