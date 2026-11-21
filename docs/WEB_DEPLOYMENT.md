# Web Deployment

## Target
Desktop browsers with WebGL 2 support.

## Release process
1. Install the matching Godot export templates.
2. Export the `Web` preset to `game/build/web`.
3. Serve the export over HTTPS.
4. Verify keyboard input, audio unlock, scene transitions and local save persistence.
5. Test a hard refresh and a new browser session.
6. Publish the exact tested artifact.

## Hosting
GitHub Pages is suitable for an initial static demo. Amazon S3 + CloudFront is an alternative for production hosting and cache control.

## Important
Do not use `file://` to test the exported game. Web builds must be served over HTTP(S). Configure correct MIME types and compression at the host/CDN.
