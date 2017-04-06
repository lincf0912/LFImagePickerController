Pod::Spec.new do |s|
s.name         = 'LFImagePickerController'
s.version      = '1.0.6'
s.summary      = 'A clone of UIImagePickerController, support picking multiple photos、 video and edit photo'
s.homepage     = 'https://github.com/lincf0912/LFImagePickerController'
s.license      = 'MIT'
s.author       = { 'lincf0912' => 'dayflyking@163.com' }
s.platform     = :ios
s.ios.deployment_target = '7.0'
s.source       = { :git => 'https://github.com/lincf0912/LFImagePickerController.git', :tag => s.version, :submodules => true }
s.requires_arc = true
s.resources    = 'LFImagePickerController/class/*.bundle'
s.source_files = 'LFImagePickerController/class/*.{h,m}','LFImagePickerController/class/**/*.{h,m}'
s.public_header_files = 'LFImagePickerController/class/*.h','LFImagePickerController/class/manager/*.h','LFImagePickerController/class/model/*.h'

end
