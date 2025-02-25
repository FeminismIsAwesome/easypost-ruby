# frozen_string_literal: true

# Parcel objects represent the physical container being shipped.
class EasyPost::Parcel < EasyPost::Resource
  # Retrieving all Parcel objects is not supported.
  def self.all
    raise NotImplementedError.new('Parcel.all not implemented.')
  end
end
