require "carrierwave/storage/tt"
require "carrierwave/tt/configuration"
CarrierWave.configure do |config|
  config.storage_engines.merge!({:tt => "CarrierWave::Storage::TT"})
end

CarrierWave::Uploader::Base.send(:include, CarrierWave::TT::Configuration)