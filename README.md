# CarrierWave for [TokyoTyrant](http://fallabs.com/tokyotyrant/)

This gem adds support for tokyotyrant to [CarrierWave](https://github.com/jnicklas/carrierwave/)

## Installation

    gem install carrierwave-tt

## Or using Bundler, in `Gemfile`

    gem 'rest-client'
    gem 'carrierwave-tt'

## Configuration

You'll need to configure the to use this in config/initializes/carrierwave.rb

```ruby
CarrierWave.configure do |config|
  config.storage = :tt
  config.host = "http://localhost"
  config.port = 1978
  config.domain = 'localhost:1978'
end
```

And then in your uploader, set the storage to `:tt`:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :tt
end
```

You can override configuration item in individual uploader like this:

```ruby
class AvatarUploader < CarrierWave::Uploader::Base
  storage :tt

end
```

## Configuration for use TT "Image Space"

```ruby
# The defined image name versions to limit use
IMAGE_UPLOADER_ALLOW_IMAGE_VERSION_NAMES = %(320 640 800)
class ImageUploader < CarrierWave::Uploader::Base
  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url
    # You can use FTP to upload a default image
    "#{Setting.upload_url}/blank.png#{version_name}"
  end

  # Override url method to implement with "Image Space"
  def url(version_name = "")
    @url ||= super({})
    version_name = version_name.to_s
    return @url if version_name.blank?
    if not version_name.in?(IMAGE_UPLOADER_ALLOW_IMAGE_VERSION_NAMES)
      # To protected version name using, when it not defined, this will be give an error message in development environment
      raise "ImageUploader version_name:#{version_name} not allow."
    end
    [@url,version_name].join("!") # thumb split with "!"
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def filename
    if super.present?
      model.uploader_secure_token ||= SecureRandom.uuid.gsub("-","")
      Rails.logger.debug("(BaseUploader.filename) #{model.uploader_secure_token}")
      "#{model.uploader_secure_token}.#{file.extension.downcase}"
    end
  end
end
```
