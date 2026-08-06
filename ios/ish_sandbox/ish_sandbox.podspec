Pod::Spec.new do |s|
  s.name             = 'ish_sandbox'
  s.version          = '0.1.0'
  s.summary          = 'iSH-ARM64 Linux sandbox plugin for Kelivo/Henglu'
  s.description      = 'Embeds an Alpine Linux shell via iSH-ARM64 into the iOS Flutter app.'
  s.homepage         = 'https://github.com/PouoO/henglu'
  s.license          = { :type => 'GPL-3.0', :file => '../../LICENSE' }
  s.author           = { 'Henglu' => 'heng@lu' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '14.0'

  s.source_files     = 'Classes/**/*.{h,m,swift}'
  s.public_header_files = 'Classes/ISH/*.h'
  s.vendored_libraries = 'Classes/deps/libs/*.a'
  s.resource_bundles = { 'iSHRootfs' => ['Classes/deps/resources/alpine-rootfs.zip'] }

  s.preserve_paths   = 'Classes/deps/include/**'
  s.xcconfig         = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Classes/deps/include"',
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load -lsqlite3',
    'OTHER_CFLAGS' => '$(inherited) -DISH_INTERNAL'
  }

  s.frameworks       = 'Foundation'
  s.libraries        = 'sqlite3', 'archive'
end
