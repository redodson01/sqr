# SQR

A QR code encoder and decoder. Rails API backend with a React frontend.

## API

- `POST /encode` — generate a QR code PNG from text (`text` param)
- `POST /decode` — decode a QR code from any image format (`file` param, multipart upload). Returns JSON with `text` (decoded content) and `qr_png` (base64-encoded clean QR PNG).

### curl examples

```sh
# Encode text to a QR code PNG
curl -X POST -F "text=https://example.com" http://localhost:3000/encode -o qr.png

# Decode a QR code image (accepts any image format)
curl -X POST -F "file=@qr.png" http://localhost:3000/decode
curl -X POST -F "file=@photo.heic" http://localhost:3000/decode
```

## Development

**Prerequisites:** Ruby 3.4+, Node 18+, ImageMagick, zbar

```sh
bundle install
cd client && npm install
```

Run the Rails server and Vite dev server separately:

```sh
bin/rails server          # http://localhost:3000
cd client && npm run dev  # http://localhost:5173
```

The Vite dev server proxies `/encode` and `/decode` to Rails.

## Tests

```sh
bin/rails test
```

## Production / Deployment

The app is configured for [Render](https://render.com) via `render.yaml` and `Dockerfile`. The Docker image installs system dependencies (zbar, ImageMagick), bundles gems, builds the React client into `public/`, and runs the Rails server.
