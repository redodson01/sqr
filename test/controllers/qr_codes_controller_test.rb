require "test_helper"

class QrCodesControllerTest < ActionDispatch::IntegrationTest
  test "encode returns a PNG image" do
    post encode_path, params: { text: "Hello SQR" }

    assert_response :success
    assert_equal "image/png", response.content_type
    assert response.body.start_with?("\x89PNG".b)
  end

  test "encode returns 400 when text is missing" do
    post encode_path

    assert_response :bad_request
    assert_equal "Missing 'text' parameter", response.parsed_body["error"]
  end

  test "decode returns text and qr_png" do
    qr = RQRCode::QRCode.new("Hello SQR")
    png_data = qr.as_png(size: 300).to_s

    file = Rack::Test::UploadedFile.new(
      StringIO.new(png_data), "image/png", true, original_filename: "qr.png"
    )

    post decode_path, params: { file: file }

    assert_response :success
    assert_equal "Hello SQR", response.parsed_body["text"]
    assert response.parsed_body["qr_png"].present?, "Expected qr_png in response"

    # Verify qr_png is valid base64-encoded PNG
    decoded_png = Base64.strict_decode64(response.parsed_body["qr_png"])
    assert decoded_png.start_with?("\x89PNG".b)
  end

  test "decode returns 400 when file is missing" do
    post decode_path

    assert_response :bad_request
    assert_equal "Missing 'file' parameter", response.parsed_body["error"]
  end

  test "decode returns 422 for image with no QR code" do
    image = ChunkyPNG::Image.new(100, 100, ChunkyPNG::Color::WHITE)
    png_data = image.to_blob

    file = Rack::Test::UploadedFile.new(
      StringIO.new(png_data), "image/png", true, original_filename: "blank.png"
    )

    post decode_path, params: { file: file }

    assert_response :unprocessable_entity
    assert_equal "No QR code found in image", response.parsed_body["error"]
  end

  test "decode accepts JPEG input" do
    png_data = RQRCode::QRCode.new("JPEG test").as_png(size: 300).to_s

    # Convert PNG to JPEG via MiniMagick
    png_image = MiniMagick::Image.read(png_data)
    png_image.format "jpg"
    jpeg_data = File.read(png_image.path, mode: "rb")

    file = Rack::Test::UploadedFile.new(
      StringIO.new(jpeg_data), "image/jpeg", true, original_filename: "qr.jpg"
    )

    post decode_path, params: { file: file }

    assert_response :success
    assert_equal "JPEG test", response.parsed_body["text"]
    assert response.parsed_body["qr_png"].present?
  end

  test "encode and decode round-trip" do
    original_text = "https://example.com/secret?token=abc123"

    post encode_path, params: { text: original_text }
    assert_response :success

    file = Rack::Test::UploadedFile.new(
      StringIO.new(response.body), "image/png", true, original_filename: "qr.png"
    )

    post decode_path, params: { file: file }
    assert_response :success
    assert_equal original_text, response.parsed_body["text"]
  end

  test "decode round-trip preserves QR content" do
    original_text = "https://example.com/roundtrip"
    png_data = RQRCode::QRCode.new(original_text).as_png(size: 300).to_s

    file = Rack::Test::UploadedFile.new(
      StringIO.new(png_data), "image/png", true, original_filename: "qr.png"
    )

    post decode_path, params: { file: file }
    assert_response :success
    assert_equal original_text, response.parsed_body["text"]

    # Decode the returned qr_png to verify content is preserved
    returned_png = Base64.strict_decode64(response.parsed_body["qr_png"])
    reencoded_file = Rack::Test::UploadedFile.new(
      StringIO.new(returned_png), "image/png", true, original_filename: "reencoded.png"
    )

    post decode_path, params: { file: reencoded_file }
    assert_response :success
    assert_equal original_text, response.parsed_body["text"]
  end
end
