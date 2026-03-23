# Sponsor Ad Images

Store sponsor creative images here (e.g. `bennys-march-2026.jpg`).

## No text in image

**Images must be visual only — no embedded text.** The `headline` field in the Gist config handles copy. Text baked into photos can appear blurry on some devices and is not controllable. Use the image for visuals (product, ambiance, logo); use the config for all copy.

## Raw URL format

After committing an image, use this URL in your [Gist ad config](https://gist.github.com/Hann8n):

```
https://raw.githubusercontent.com/Hann8n/VTGymTracker/main/docs/images/sponsors/{filename}
```

Replace `{filename}` with your image (e.g. `bennys-march-2026.jpg`).

## Workflow

1. Add image to this folder
2. Commit and push
3. Update Gist `image_url` with the raw URL above
