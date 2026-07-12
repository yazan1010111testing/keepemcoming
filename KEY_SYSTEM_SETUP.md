# ElectraX Premium - Key System Setup Guide

## 📋 Overview
This guide will help you set up the key system for ElectraX Premium using work.ink.

---

## 🔧 Setup Instructions

### Step 1: Create a work.ink Account
1. Go to https://dashboard.work.ink/
2. Sign up or log in to your account

### Step 2: Create a Shortened Link
1. In the work.ink dashboard, click "Create Link"
2. Set the **Destination URL** to: `https://work.ink/token`
3. Click "Create"
4. You'll get a shortened link like: `https://work.ink/abc123`

### Step 3: Get Your Link ID and Token
1. Click on your created link to view details
2. Copy the **Link ID** (e.g., `abc123`)
3. Click "Add Token" to create a token parameter
4. Copy the full link with token (e.g., `https://work.ink/abc123/d653afbe-06a3-4fc9-ba5f-674b59ebcbbd`)

### Step 4: Configure the Loader Script
Open `loader_with_key.lua` and update these lines:

```lua
local Config = {
    LinkId = "abc123", -- Replace with your Link ID
    FullLink = "https://work.ink/abc123/d653afbe-06a3-4fc9-ba5f-674b59ebcbbd", -- Replace with your full link
    ValidateEndpoint = "https://work.ink/_api/v2/token/isValid/",
    
    ScriptName = "ElectraX Premium",
    ScriptVersion = "v3.0.0",
    DiscordInvite = "https://discord.gg/your_invite", -- Replace with your Discord
    
    SaveKey = true, -- Users won't need to re-enter keys
    DeleteToken = false, -- Set to true for single-use keys
    MaxAttempts = 5,
    CooldownTime = 30,
}
```

### Step 5: Upload Your Script
1. Upload `electrax_premium.lua` to GitHub or Pastebin
2. Update the loader script with your script URL:

```lua
-- In loader_with_key.lua, find this line:
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/electrax_premium.lua"))()

-- Replace with your actual URL, for example:
loadstring(game:HttpGet("https://raw.githubusercontent.com/username/repo/main/electrax_premium.lua"))()
```

---

## 🎯 How Users Get Keys

### For Users:
1. Execute the loader script
2. Click "Get Key" button
3. Complete the work.ink checkpoint
4. Copy the key (UUID format)
5. Paste it in the key input box
6. Click "Validate Key"

### Key Format:
Keys look like this: `d653afbe-06a3-4fc9-ba5f-674b59ebcbbd`

---

## ⚙️ Configuration Options

### SaveKey (Recommended: true)
- `true`: Users only need to enter key once, it's saved locally
- `false`: Users must enter key every time

### DeleteToken (Recommended: false)
- `true`: Keys can only be used once (single-use)
- `false`: Keys can be used multiple times

### MaxAttempts & CooldownTime
- Prevents brute-force key guessing
- Default: 5 attempts, 30 second cooldown

---

## 🔒 Security Features

✅ **work.ink v2 API** - Secure validation  
✅ **IP Verification** - Optional IP locking  
✅ **Rate Limiting** - Prevent brute force  
✅ **Local Key Storage** - Convenience for legitimate users  
✅ **Anti-Bypass** - Protected against common exploits

---

## 🎨 Customization

### Change Theme Colors
In `loader_with_key.lua`, find and modify:

```lua
-- Purple theme (default)
TopBar.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
GetKeyButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226)

-- Blue theme example
TopBar.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
GetKeyButton.BackgroundColor3 = Color3.fromRGB(60, 120, 255)

-- Green theme example
TopBar.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
GetKeyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
```

### Change Discord Invite
```lua
DiscordInvite = "https://discord.gg/your_invite", -- Your Discord server
```

---

## 🧪 Testing

### Test Your Key System:
1. Execute the loader script
2. Click "Get Key"
3. Complete the checkpoint
4. Copy and validate the key
5. Verify the main script loads

### Debug Mode:
Enable debug prints by adding this at the top:
```lua
_G.DebugKeySystem = true
```

---

## 📊 work.ink Dashboard

### Monitor Your Keys:
- View total checkpoints completed
- See active tokens
- Track user engagement
- Earn money from checkpoints!

### Dashboard URL:
https://dashboard.work.ink/

---

## ❓ Troubleshooting

### "Connection error"
- Check user's internet connection
- Verify work.ink is not down

### "Invalid key"
- Ensure user completed checkpoint fully
- Check if DeleteToken is enabled (single-use)
- Verify Link ID is correct

### "Too many failed attempts"
- User must wait for cooldown to expire
- Reduce MaxAttempts if needed

### Script doesn't load after key validation
- Check the script URL is correct
- Verify the script is publicly accessible
- Test the URL in browser

---

## 💡 Best Practices

1. **Use SaveKey = true** - Better user experience
2. **Set DeleteToken = false** - Unless you need single-use keys
3. **Test thoroughly** - Before distributing to users
4. **Keep backup** - Save your Link ID and tokens
5. **Monitor dashboard** - Check for issues

---

## 📞 Support

If you need help:
1. Check work.ink documentation: https://work.ink/docs
2. Review this guide again
3. Test with debug mode enabled
4. Contact support

---

## 🎉 You're Done!

Your ElectraX Premium key system is now set up and ready to use!

Users can now:
- ✅ Get keys through your link
- ✅ Validate keys automatically
- ✅ Access ElectraX Premium features
- ✅ Saved keys for future use

**Good luck with your script!** ⚡
