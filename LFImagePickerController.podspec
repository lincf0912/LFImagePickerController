Pod::Spec.new do |s|
s.name         = "LFImagePickerController"
s.version      = "1.0"
s.summary      = "A clone of UIImagePickerController, support picking multiple photos、 video and edit photo"
s.homepage     = "https://github.com/lincf0912/LFImagePickerController"
s.license      = "MIT"
s.author       = { "lincf0912" => "dayflyking@163.com" }
s.platform     = :ios
s.ios.deployment_target = "7.0"
s.source       = { :git => "https://github.com/lincf0912/LFImagePickerController.git", :tag => "1.0" }
s.requires_arc = true
s.resources    = "LFImagePickerController/class/*.{png,xib,nib,bundle}"
s.source_files = "LFImagePickerController/class/*.{h,m}"
end
