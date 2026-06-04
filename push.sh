cat > push.sh << 'EOF'
#!/bin/bash
set -e

TOKEN="PASTE_TOKEN_ANDA_DISINI"
USER="username-anda"
REPO="payroll-system"

git init
git add .
git commit -m "feat: initial payroll system" || echo "nothing to commit"
git branch -M main
git remote add origin "https://${TOKEN}@github.com/${USER}/${REPO}.git"
git push -u origin main
git remote set-url origin "https://github.com/${USER}/${REPO}.git"

echo "✅ Sukses push ke https://github.com/${USER}/${REPO}"
EOF

chmod +x push.sh
