#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint firebase_hybrid_ai.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'firebase_hybrid_ai'
  s.version          = '0.0.2'
  s.summary          = 'Bridges Flutter to on-device and cloud models, chosen by inference mode.'
  s.description      = <<-DESC
Runs prompts on Apple's on-device model or on a Gemini model through Firebase AI Logic, and falls back from one to the other.
                       DESC
  s.homepage         = 'https://github.com/Toglefritz/cupward/tree/main/firebase_hybrid_ai'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Splendid Endeavors LLC'
  s.source           = { :path => '.' }
  s.source_files = 'firebase_hybrid_ai/Sources/firebase_hybrid_ai/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'firebase_hybrid_ai_privacy' => ['firebase_hybrid_ai/Sources/firebase_hybrid_ai/PrivacyInfo.xcprivacy']}
end
