# Create Cloudinary Upload Preset - Step by Step

## The Problem
You created a **folder** but need an **upload preset**. These are different things in Cloudinary.

## Step-by-Step Solution

### 1. Go to Cloudinary Console
- Open: https://cloudinary.com/console
- Log in with your account
- Make sure you're in the correct cloud: `dm9oh76nw`

### 2. Navigate to Upload Presets
- Click **"Settings"** (gear icon) in the left sidebar
- Click **"Upload"** in the settings menu
- Click **"Upload presets"** tab
- You should see a list of existing presets (if any)

### 3. Create New Upload Preset
- Click **"Add upload preset"** button (usually blue button)
- Fill in the form:

#### Basic Settings:
- **Preset name**: `shopradar_profiles` (exactly this name)
- **Signing Mode**: Select **"Unsigned"** (very important!)
- **Folder**: `shopradar/profiles`

#### Transformations (Optional but recommended):
- **Width**: `400`
- **Height**: `400`
- **Crop**: `fill`
- **Gravity**: `face`
- **Quality**: `auto`
- **Format**: `auto`

### 4. Save the Preset
- Click **"Save"** button
- You should see the new preset in your list

### 5. Verify the Preset
- The preset should show:
  - Name: `shopradar_profiles`
  - Signing: `Unsigned`
  - Folder: `shopradar/profiles`

## Alternative: Use Signed Upload (No Preset Needed)

If you can't create the preset, let's modify the code to use signed uploads instead:
