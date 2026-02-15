require "open3"

class QrCodesController < ApplicationController
  def encode
    text = params[:text]
    return render json: { error: "Missing 'text' parameter" }, status: :bad_request if text.blank?

    qr = RQRCode::QRCode.new(text)
    png = qr.as_png(size: 300)
    png_data = png.to_datastream(color_mode: ChunkyPNG::COLOR_TRUECOLOR).to_s

    send_data png_data, type: "image/png", disposition: "inline"
  end

  def decode
    file = params[:file]
    return render json: { error: "Missing 'file' parameter" }, status: :bad_request if file.blank?

    begin
      converted = MiniMagick::Image.read(file.tempfile)
      converted.format "png"
      converted.resize "800x800>"
    rescue MiniMagick::Error => e
      logger.error "MiniMagick failed: #{e.message}"
      return render json: { error: "Could not process image" }, status: :unprocessable_entity
    end

    output, status = Open3.capture2("zbarimg", "--quiet", "--raw", converted.path, err: File::NULL)

    if !status.success? || output.blank?
      return render json: { error: "No QR code found in image" }, status: :unprocessable_entity
    end

    text = output.strip

    qr = RQRCode::QRCode.new(text)
    png = qr.as_png(size: 300)
    png_data = png.to_datastream(color_mode: ChunkyPNG::COLOR_TRUECOLOR).to_s

    render json: { text: text, qr_png: Base64.strict_encode64(png_data) }
  rescue => e
    logger.error "Decode failed: #{e.class}: #{e.message}"
    render json: { error: "Could not process image" }, status: :internal_server_error
  end
end
