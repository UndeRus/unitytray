Ubuntu: 

1. Install dependencies:
sudo apt-get install libappindicator-dev libgtk2.0-dev

2. Build binary

make

3. Add this row to ~/.tkabber/config.tcl(will be removed in future)

set ::unitytray {presence chat_message}


4. Run tkabber and enable extension
