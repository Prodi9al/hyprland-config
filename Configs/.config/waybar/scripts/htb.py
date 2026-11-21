#!/usr/bin/env python3
import sys
import os
import json
import time
import urllib.request
import urllib.error
import subprocess

USER_ID = "2426022"
CACHE_DIR = os.path.expanduser("~/.cache/waybar")
CACHE_FILE = os.path.join(CACHE_DIR, "htb_profile.json")
TOKEN_FILE = os.path.expanduser("~/.config/waybar/scripts/htb_token.env")
CACHE_MAX_AGE = 900  # 15 minutes

def get_token():
    token = os.environ.get("HTB_TOKEN", "").strip()
    if token:
        return token
    if os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE, "r") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("export HTB_TOKEN="):
                        val = line.split("=", 1)[1].strip()
                        return val.strip("\"'")
                    elif line.startswith("HTB_TOKEN="):
                        val = line.split("=", 1)[1].strip()
                        return val.strip("\"'")
        except Exception:
            pass
    return ""

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                data = json.load(f)
            return data
        except Exception:
            pass
    return None

def save_cache(data):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass

def fetch_profile():
    token = get_token()
    url = f"https://labs.hackthebox.com/api/v4/user/profile/basic/{USER_ID}"
    headers = {
        "User-Agent": "Prodigal/1.0",
        "Accept": "application/json"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=7) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                if data and "profile" in data:
                    data["_fetched_at"] = time.time()
                    save_cache(data)
                    return data
    except Exception:
        pass
    return None

def format_output(data):
    if not data:
        return {
            "text": " HTB Offline",
            "tooltip": "Could not reach Hack The Box API\n<small>Right-click to retry</small>",
            "class": "offline"
        }
    
    p = data.get("profile", {})
    name = p.get("name", "HTB")
    rank = p.get("rank", "Player")
    points = p.get("points", 0)
    ranking = p.get("ranking", "N/A")
    progress = p.get("current_rank_progress", 0)
    next_rank = p.get("next_rank", "")
    user_owns = p.get("user_owns", 0)
    sys_owns = p.get("system_owns", 0)
    respects = p.get("respects", 0)
    country = p.get("country_name", "Global")
    server = p.get("server", "N/A")

    text = f" {rank} · {points} pts"
    tooltip = (
        f"<b>{name}</b> ({country})\n"
        f"Rank: <b>{rank}</b> ({progress}% to {next_rank})\n"
        f"Ranking: #{ranking} | Points: {points}\n"
        f"Owns: {user_owns} User / {sys_owns} System | Respects: {respects}\n"
        f"Server: {server}\n"
        f"<small>Left: Open Profile | Right: Refresh</small>"
    )
    return {
        "text": text,
        "tooltip": tooltip,
        "class": rank.lower().replace(" ", "-"),
        "percentage": int(float(progress or 0))
    }

def main():
    force_refresh = "--refresh" in sys.argv
    notify = "--notify" in sys.argv

    cached = load_cache()
    now = time.time()

    data = None
    if force_refresh or not cached or (now - cached.get("_fetched_at", 0) > CACHE_MAX_AGE):
        data = fetch_profile()
    
    if not data:
        data = cached

    out = format_output(data)

    if notify or force_refresh:
        p = data.get("profile", {}) if data else {}
        summary = f"HTB: {p.get('name', 'User')}"
        body = f"Rank: {p.get('rank', 'N/A')} ({p.get('points', 0)} pts)\nRanking: #{p.get('ranking', 'N/A')}\nOwns: {p.get('user_owns', 0)} U / {p.get('system_owns', 0)} S"
        try:
            subprocess.Popen(["notify-send", "-a", "Hack The Box", "-i", "network-vpn", summary, body])
        except Exception:
            pass

    print(json.dumps(out))

if __name__ == "__main__":
    main()
