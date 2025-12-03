Pod::Spec.new do |s|
  s.name             = 'MarkdownUI'
  s.version          = '0.1.0'
  s.summary          = 'SwiftUI-based Markdown rendering components.'
  s.description      = <<-DESC
  MarkdownUI provides SwiftUI views and helpers to render GitHub-flavored Markdown
  with support for images, lists, tables, code, and theming.
  DESC
  s.homepage         = 'https://github.com/gapoworkios/swift-markdown-ui'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'gapoworkios' => 'dev@gapo.work' }
  s.source           = { :git => 'https://github.com/gapoworkios/swift-markdown-ui.git', :tag => s.version.to_s }

  # Swift tools & platforms
  s.swift_version    = '5.6'
  s.ios.deployment_target        = '13.0'
  s.osx.deployment_target        = '12.0'
  s.tvos.deployment_target       = '15.0'
  s.watchos.deployment_target    = '8.0'

  # Source files
  s.source_files     = 'Sources/MarkdownUI/**/*.swift'
  s.resources        = ['Sources/MarkdownUI/Documentation.docc/**/*']

  # Specify module name to match SwiftPM product
  s.module_name      = 'MarkdownUI'

  # SPM dependencies (requires cocoapods-spm plugin)
  # Declare SPM package products using spm_dependency
  s.spm_dependency 'swift-cmark/cmark-gfm'
  s.spm_dependency 'swift-cmark/cmark-gfm-extensions'
  s.spm_dependency 'NetworkImage/NetworkImage'
end