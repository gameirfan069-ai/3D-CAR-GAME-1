# Street Legends 3D (v0.2)

An original Godot 4.4 driving prototype: open city, coins on the road, a dealership to buy cars with coins, a garage to pick and paint cars, and touch controls for phones.

## What changed from v0.1

- **Road fixed.** Buildings were blocking the main road at about 60 m. The road is now clear for the full 650 m.
- **Junction fixed.** The cross road was 1 cm higher than the main road and stopped the car at the junction.
- **Phone steering added.** Touch zones for LEFT / RIGHT / BRAKE / GAS, with multi-touch.
- **Landscape on phones.** Set in `project.godot`.
- **Reverse steering** now works like a real car.
- **Wheels sit on the road** (the collision box reaches the ground).
- **Coins:** pick them up on the road for 250 each. Coins are saved between sessions.
- **Dealership and garage:** 7 cars (`scripts/car_catalog.gd`), turntable preview, stats bars, paint colours.
- **Graphics:** windowed buildings, street lamps, curbs, fog, filmic tone mapping, a chase camera that speeds up its field of view with speed.

## Controls

- Keyboard: W/Up accelerate, S/Down brake, A/Left and D/Right steer.
- Phone: touch zones at the bottom of the screen.

## Run it on a computer

1. Install Godot 4.4 (standard version, not .NET) from https://godotengine.org.
2. Open Godot, click **Import**, choose this folder's `project.godot`.
3. Press **Play** (F5).

## Put it on GitHub (no coding needed)

1. Create a free account at github.com, then click **New repository**. Name it `street-legends-3d`, set it to Private, and tick "Add a README" off.
2. Upload these files: on the new repo page click **Add file → Upload files**, drag the **contents** of this folder in (including the hidden `.github` folder and `.gitignore`), then **Commit changes**. On a phone, the GitHub website works in the browser; the GitHub mobile app can't upload folders.
3. Click the **Actions** tab. The workflow **Build Android APK** starts automatically. It runs a smoke test first, then builds the APK.
4. When it finishes (about 5–15 minutes), open the run and download **StreetLegends3D-apk** from "Artifacts". Unzip it to get `StreetLegends3D.apk`.
5. Copy the APK to your phone and install it. You'll need to allow installing from unknown sources.

If the build fails, open the failed step's log in the Actions tab and send me the last 30 lines. I can't run the Android export here, so this is the first real build to check.

## Known limits (honest)

- **Car models are placeholders** built from boxes and cylinders. For real GT-style graphics you need original, optimised 3D models (`.glb`). Make them yourself in Blender, or buy assets with a licence that allows commercial use. Replace `scripts/car_builder.gd` with a loader for each model.
- **Brand names.** "BMW", "Mercedes-AMG", "Porsche", "Audi" and "Lamborghini" are trademarks. Fine for private testing. Before publishing on the Play Store, either get permission or rename the cars (edit `name` in `scripts/car_catalog.gd`). The brand-free starter car is "Street Coupe".
- **Not tested on a real phone or Android export.** The desktop build was tested headless with Godot 4.4 and rendered to screenshots under a virtual display. The APK build is set up but has not been run.
- **No racing, AI traffic or missions yet.** The next steps are a race mode (checkpoints, positions, lap timer), upgrades (engine/turbo/suspension bought with coins), and sound.
- **Playing on phones:** the touch controls are only shown on touch screens. Desktop shows none.

## Files

- `project.godot`: settings, landscape on phones.
- `scenes/main.tscn`: the one scene, which runs `scripts/world.gd`.
- `scripts/world.gd`: environment, roads, city, coins, camera, game state.
- `scripts/hud.gd`: menu, dealership, garage, driving HUD, touch controls.
- `scripts/player_car.gd`: driving physics.
- `scripts/car_builder.gd`: builds each car's look.
- `scripts/car_catalog.gd`: car list, prices, stats, paint colours.
- `scripts/save_data.gd`: saves coins, owned cars and paint.
- `export_presets.cfg`: Android export settings used by the workflow.
- `.github/workflows/android-apk.yml`: GitHub Actions build.
