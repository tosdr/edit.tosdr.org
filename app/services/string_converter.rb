# lib/services/string_converter.rb
class Services::StringConverter
  def initialize(string:)
    @string = string
  end

  def to_uuid
    utf_encoded = @string.encode('UTF-8') + '=='.encode('UTF-8')
    # Returns the Base64-decoded version of str
    # https://ruby-doc.org/stdlib-2.4.0/libdoc/base64/rdoc/Base64.html#method-i-urlsafe_decode64
    b64_decoded = Base64.urlsafe_decode64(utf_encoded)
    # unpack decoded with uuid format
    # https://apidock.com/ruby/String/unpack
    b64_decoded.unpack('H8H4H4H4H12').join('-')
  end

  def to_url_safe
    hex_string = UUID.validate(@string) && @string.split("-").join
    data = Binascii.a2b_hex(hex_string)
    b64_encoded = Base64.urlsafe_encode64(data)
    b64_encoded[0...-2]
  end
end
