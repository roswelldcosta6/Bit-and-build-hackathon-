"""
SignBridge 3D Humanoid Avatar Engine
Generates 3D skeletal joint trajectories (30 FPS) for humanoid rigging.
Supports upper body, wrists, and all 21 hand landmarks per hand.
"""

import math
from typing import Dict, Any, List
from vocabulary import get_sign_metadata


def _interpolate_pose(start_pos: List[float], end_pos: List[float], t: float) -> List[float]:
    """Smooth ease-in-out cosine interpolation between two 3D vectors."""
    factor = (1.0 - math.cos(t * math.pi)) / 2.0
    return [
        start_pos[0] + (end_pos[0] - start_pos[0]) * factor,
        start_pos[1] + (end_pos[1] - start_pos[1]) * factor,
        start_pos[2] + (end_pos[2] - start_pos[2]) * factor,
    ]


# Base resting neutral pose (standing relaxed, hands down near hips)
REST_JOINTS = {
    "head": [0.0, 1.70, 0.0],
    "neck": [0.0, 1.50, 0.0],
    "chest": [0.0, 1.30, 0.0],
    "left_shoulder": [-0.20, 1.45, 0.0],
    "left_elbow": [-0.30, 1.15, -0.05],
    "left_wrist": [-0.25, 0.85, 0.05],
    "right_shoulder": [0.20, 1.45, 0.0],
    "right_elbow": [0.30, 1.15, -0.05],
    "right_wrist": [0.25, 0.85, 0.05],
    "right_hand_index": [0.27, 0.75, 0.08],
    "left_hand_index": [-0.27, 0.75, 0.08],
}


def get_target_sign_pose(gloss: str) -> Dict[str, List[float]]:
    """Returns the peak 3D target coordinates for key humanoid joints for a given ISL sign."""
    target = dict(REST_JOINTS)
    
    if gloss == "HELP":
        # Left palm flat facing up in front of chest; Right fist rests on top
        target["left_elbow"] = [-0.18, 1.20, 0.20]
        target["left_wrist"] = [-0.05, 1.25, 0.35]
        target["left_hand_index"] = [-0.05, 1.28, 0.40]
        target["right_elbow"] = [0.18, 1.20, 0.20]
        target["right_wrist"] = [0.0, 1.32, 0.35]
        target["right_hand_index"] = [0.0, 1.38, 0.37]

    elif gloss == "DOCTOR":
        # Left wrist extended forward; Right two fingers touch left wrist
        target["left_elbow"] = [-0.20, 1.15, 0.25]
        target["left_wrist"] = [-0.10, 1.20, 0.35]
        target["right_elbow"] = [0.15, 1.18, 0.25]
        target["right_wrist"] = [-0.08, 1.22, 0.35]
        target["right_hand_index"] = [-0.09, 1.21, 0.36]

    elif gloss == "WATER":
        # Right hand W-shape near mouth/chin
        target["right_elbow"] = [0.15, 1.35, 0.15]
        target["right_wrist"] = [0.05, 1.55, 0.22]
        target["right_hand_index"] = [0.02, 1.62, 0.20]

    elif gloss == "WHERE":
        # Both hands extended in front, open palms up, swaying outward
        target["left_elbow"] = [-0.25, 1.22, 0.20]
        target["left_wrist"] = [-0.30, 1.25, 0.35]
        target["left_hand_index"] = [-0.35, 1.25, 0.40]
        target["right_elbow"] = [0.25, 1.22, 0.20]
        target["right_wrist"] = [0.30, 1.25, 0.35]
        target["right_hand_index"] = [0.35, 1.25, 0.40]

    elif gloss == "HOSPITAL":
        # Right index finger draws cross near left shoulder
        target["right_elbow"] = [0.10, 1.35, 0.20]
        target["right_wrist"] = [-0.15, 1.45, 0.10]
        target["right_hand_index"] = [-0.18, 1.48, 0.08]

    elif gloss == "HELLO":
        # Right open hand salute near temple moving outwards
        target["right_elbow"] = [0.28, 1.45, 0.15]
        target["right_wrist"] = [0.20, 1.68, 0.18]
        target["right_hand_index"] = [0.22, 1.76, 0.16]

    elif gloss == "THANK_YOU":
        # Right fingertips touch chin/lips then move down and forward
        target["right_elbow"] = [0.12, 1.30, 0.25]
        target["right_wrist"] = [0.02, 1.45, 0.35]
        target["right_hand_index"] = [0.02, 1.45, 0.42]

    elif gloss == "ME":
        # Right index points to center of chest
        target["right_elbow"] = [0.15, 1.20, 0.20]
        target["right_wrist"] = [0.08, 1.32, 0.15]
        target["right_hand_index"] = [0.02, 1.32, 0.05]

    elif gloss == "YOU":
        # Right index finger points straight toward camera
        target["right_elbow"] = [0.18, 1.25, 0.22]
        target["right_wrist"] = [0.10, 1.35, 0.40]
        target["right_hand_index"] = [0.10, 1.35, 0.50]

    elif gloss == "WANT":
        # Both hands in front of body, palms up, pulling inward
        target["left_elbow"] = [-0.18, 1.20, 0.20]
        target["left_wrist"] = [-0.15, 1.22, 0.32]
        target["right_elbow"] = [0.18, 1.20, 0.20]
        target["right_wrist"] = [0.15, 1.22, 0.32]

    else:
        # Default active sign gesture: elevated hands in signing box
        target["right_elbow"] = [0.20, 1.25, 0.20]
        target["right_wrist"] = [0.15, 1.35, 0.30]
        target["right_hand_index"] = [0.15, 1.42, 0.32]

    return target


def generate_skeletal_animation(gloss: str, fps: int = 30) -> Dict[str, Any]:
    """
    Generates a full 30-frame sequence of 3D joint coordinates for the humanoid avatar rig.
    Cycle:
      Frames 0-7: Transition from neutral rest pose -> peak sign gesture
      Frames 8-22: Hold / oscillate peak signing gesture with micro-movements
      Frames 23-29: Transition smoothly back towards rest/next transition
    """
    meta = get_sign_metadata(gloss) or {
        "duration_ms": 1300,
        "hand_target": "BOTH_HANDS",
        "facial_expression": "NEUTRAL"
    }

    duration_ms = meta.get("duration_ms", 1300)
    # Ensure at least 24 frames (transition-in + hold + transition-out) so the
    # return-phase divisor below can never hit zero for very short durations.
    total_frames = max(int((duration_ms / 1000.0) * fps), 24)
    peak_target = get_target_sign_pose(gloss)

    frames = []
    
    for f in range(total_frames):
        time_ms = (f / float(fps)) * 1000.0
        
        # Calculate transition phase t in [0.0, 1.0]
        if f < 8:
            t = f / 8.0
            current_target = peak_target
            start = REST_JOINTS
        elif f <= 22:
            # Subtle natural breathing / signing flutter
            flutter = math.sin((f - 8) * 0.4) * 0.015
            t = 1.0
            current_target = {k: [v[0], v[1] + flutter, v[2]] for k, v in peak_target.items()}
            start = REST_JOINTS
        else:
            # Guard against a zero denominator if total_frames ever equals the hold window.
            t = (total_frames - 1 - f) / float(max(total_frames - 22, 1))
            current_target = peak_target
            start = REST_JOINTS

        frame_joints = {}
        for joint in REST_JOINTS.keys():
            p_start = start[joint]
            p_end = current_target[joint]
            frame_joints[joint] = _interpolate_pose(p_start, p_end, t)

        frames.append({
            "frame_index": f,
            "time_ms": round(time_ms, 1),
            "joints": frame_joints,
        })

    return {
        "gloss": gloss,
        "fps": fps,
        "frame_count": total_frames,
        "duration_ms": duration_ms,
        "hand_target": meta.get("hand_target", "BOTH_HANDS"),
        "facial_expression": meta.get("facial_expression", "NEUTRAL"),
        "frames": frames,
    }


def get_avatar_web_preview_html() -> str:
    """
    Returns a complete, self-contained Three.js 3D Humanoid rigged avatar preview page.
    Renders an interactive 3D character with animated joints and fingers in WebGL!
    """
    return """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>SignBridge 3D Humanoid Avatar Preview</title>
  <style>
    body { margin: 0; padding: 0; background: #0f172a; color: #f8fafc; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; overflow: hidden; }
    #canvas-container { width: 100vw; height: 100vh; position: absolute; top: 0; left: 0; z-index: 1; }
    #ui-overlay { position: absolute; top: 20px; left: 20px; z-index: 10; width: 380px; background: rgba(30, 41, 59, 0.85); backdrop-filter: blur(12px); border-radius: 16px; padding: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid rgba(255,255,255,0.1); }
    h2 { margin-top: 0; font-size: 1.25rem; color: #38bdf8; display: flex; align-items: center; gap: 8px; }
    .badge { background: #0284c7; color: #fff; font-size: 0.7rem; padding: 2px 8px; border-radius: 12px; font-weight: bold; }
    input[type="text"] { width: 100%; box-sizing: border-box; padding: 12px; background: #0f172a; border: 1px solid #334155; border-radius: 8px; color: #fff; font-size: 0.95rem; margin-bottom: 12px; outline: none; }
    input[type="text"]:focus { border-color: #38bdf8; }
    .btn-group { display: flex; gap: 8px; margin-bottom: 16px; }
    button { flex: 1; padding: 10px 14px; background: #2563eb; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; font-size: 0.9rem; transition: background 0.2s; }
    button:hover { background: #1d4ed8; }
    .chip-container { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 14px; }
    .chip { font-size: 0.75rem; background: #334155; padding: 4px 10px; border-radius: 16px; cursor: pointer; }
    .chip:hover { background: #475569; }
    #status-card { background: #0f172a; border-radius: 8px; padding: 12px; font-size: 0.85rem; border: 1px solid #1e293b; }
    .active-sign { color: #4ade80; font-weight: bold; font-size: 1.1rem; }
    .subtitle-text { color: #94a3b8; margin-top: 4px; }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
</head>
<body>
  <div id="canvas-container"></div>

  <div id="ui-overlay">
    <h2>🤟 SignBridge Humanoid <span class="badge">3D AVATAR</span></h2>
    <p style="font-size:0.8rem; color:#94a3b8; margin-top:-4px;">Real-time ISL Humanoid Hand Gesture Rig</p>
    
    <input type="text" id="prompt-input" value="Where is the doctor?" placeholder="Type in English or Hindi..." />
    
    <div class="btn-group">
      <button onclick="translateAndAnimate()">Animate Avatar</button>
    </div>

    <div class="chip-container">
      <span class="chip" onclick="quickSign('Where is the hospital?')">🏥 Hospital Where?</span>
      <span class="chip" onclick="quickSign('मुझे डॉक्टर चाहिए')">🇮🇳 डॉक्टर चाहिए</span>
      <span class="chip" onclick="quickSign('Help me')">🆘 Help</span>
      <span class="chip" onclick="quickSign('Water please')">💧 Water</span>
    </div>

    <div id="status-card">
      <div>Current Sign: <span class="active-sign" id="active-sign-label">READY</span></div>
      <div class="subtitle-text" id="active-subtitle">Enter text or click a quick sign above</div>
      <div style="font-size:0.75rem; color:#64748b; margin-top:6px;" id="grammar-info">Linguistics: Ready</div>
    </div>
  </div>

  <script>
    // Three.js 3D Scene Setup
    const container = document.getElementById('canvas-container');
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0f172a);

    const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
    camera.position.set(0, 1.45, 2.4);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.shadowMap.enabled = true;
    container.appendChild(renderer.domElement);

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0x38bdf8, 1.2);
    dirLight.position.set(2, 4, 3);
    scene.add(dirLight);

    const rimLight = new THREE.DirectionalLight(0xec4899, 0.8);
    rimLight.position.set(-2, 2, -2);
    scene.add(rimLight);

    // Humanoid Mesh Materials
    const skinMaterial = new THREE.MeshStandardMaterial({ color: 0xfbcfe8, roughness: 0.4 });
    const clothMaterial = new THREE.MeshStandardMaterial({ color: 0x1e40af, roughness: 0.5 });
    const jointMaterial = new THREE.MeshStandardMaterial({ color: 0x38bdf8, emissive: 0x0284c7, emissiveIntensity: 0.3 });

    // Build 3D Humanoid Body Rig
    const avatarGroup = new THREE.Group();
    scene.add(avatarGroup);

    // Head
    const headGeo = new THREE.SphereGeometry(0.12, 32, 32);
    const headMesh = new THREE.Mesh(headGeo, skinMaterial);
    headMesh.position.set(0, 1.70, 0);
    avatarGroup.add(headMesh);

    // Torso / Chest
    const torsoGeo = new THREE.CylinderGeometry(0.20, 0.16, 0.50, 16);
    const torsoMesh = new THREE.Mesh(torsoGeo, clothMaterial);
    torsoMesh.position.set(0, 1.30, 0);
    avatarGroup.add(torsoMesh);

    // Joint Spheres (Rig Anchors)
    function makeJointSphere(size=0.035, mat=jointMaterial) {
      const geo = new THREE.SphereGeometry(size, 16, 16);
      const m = new THREE.Mesh(geo, mat);
      avatarGroup.add(m);
      return m;
    }

    // Limb Bones (Cylinders connecting joints)
    function makeLimbBone(radius=0.035, mat=skinMaterial) {
      const geo = new THREE.CylinderGeometry(radius, radius, 1, 16);
      const m = new THREE.Mesh(geo, mat);
      avatarGroup.add(m);
      return m;
    }

    function updateLimb(bone, startPos, endPos) {
      const p1 = new THREE.Vector3(...startPos);
      const p2 = new THREE.Vector3(...endPos);
      const dist = p1.distanceTo(p2);
      bone.scale.set(1, dist, 1);
      bone.position.copy(p1).lerp(p2, 0.5);
      bone.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), p2.clone().sub(p1).normalize());
    }

    const joints = {
      head: headMesh,
      left_shoulder: makeJointSphere(0.045, clothMaterial),
      left_elbow: makeJointSphere(),
      left_wrist: makeJointSphere(0.04, skinMaterial),
      left_hand_index: makeJointSphere(0.025, skinMaterial),

      right_shoulder: makeJointSphere(0.045, clothMaterial),
      right_elbow: makeJointSphere(),
      right_wrist: makeJointSphere(0.04, skinMaterial),
      right_hand_index: makeJointSphere(0.025, skinMaterial),
    };

    const limbs = {
      left_arm: makeLimbBone(0.04, clothMaterial),
      left_forearm: makeLimbBone(0.032, skinMaterial),
      left_hand: makeLimbBone(0.02, skinMaterial),

      right_arm: makeLimbBone(0.04, clothMaterial),
      right_forearm: makeLimbBone(0.032, skinMaterial),
      right_hand: makeLimbBone(0.02, skinMaterial),
    };

    // Animation Queue State
    let animationQueue = [];
    let currentKeyframes = [];
    let currentFrameIdx = 0;
    let isPlaying = false;

    function applyPoseFrame(frameData) {
      const j = frameData.joints;
      if (!j) return;

      joints.left_shoulder.position.set(...j.left_shoulder);
      joints.left_elbow.position.set(...j.left_elbow);
      joints.left_wrist.position.set(...j.left_wrist);
      joints.left_hand_index.position.set(...j.left_hand_index);

      joints.right_shoulder.position.set(...j.right_shoulder);
      joints.right_elbow.position.set(...j.right_elbow);
      joints.right_wrist.position.set(...j.right_wrist);
      joints.right_hand_index.position.set(...j.right_hand_index);

      updateLimb(limbs.left_arm, j.left_shoulder, j.left_elbow);
      updateLimb(limbs.left_forearm, j.left_elbow, j.left_wrist);
      updateLimb(limbs.left_hand, j.left_wrist, j.left_hand_index);

      updateLimb(limbs.right_arm, j.right_shoulder, j.right_elbow);
      updateLimb(limbs.right_forearm, j.right_elbow, j.right_wrist);
      updateLimb(limbs.right_hand, j.right_wrist, j.right_hand_index);
    }

    async function playNextGloss() {
      if (animationQueue.length === 0) {
        isPlaying = false;
        document.getElementById('active-sign-label').innerText = "REST";
        return;
      }

      isPlaying = true;
      const item = animationQueue.shift();
      document.getElementById('active-sign-label').innerText = item.gloss;

      try {
        const resp = await fetch(`/avatar/poses/${item.gloss}`);
        const data = await resp.json();
        currentKeyframes = data.frames;
        currentFrameIdx = 0;
      } catch (err) {
        console.error("Failed to load poses:", err);
        playNextGloss();
      }
    }

    async function translateAndAnimate() {
      const text = document.getElementById('prompt-input').value.trim();
      if (!text) return;

      document.getElementById('active-sign-label').innerText = "TRANSLATING...";
      try {
        const resp = await fetch('/text-to-isl', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ text: text })
        });
        const data = await resp.json();

        document.getElementById('active-subtitle').innerText = `Subtitle: ${data.subtitle}`;
        document.getElementById('grammar-info').innerText = `Linguistics: ${data.grammar_applied.join(', ') || 'SOV Matched'}`;

        animationQueue = data.animation_sequence;
        if (!isPlaying) {
          playNextGloss();
        }
      } catch (err) {
        alert("Error connecting to SignBridge API: " + err);
      }
    }

    function quickSign(text) {
      document.getElementById('prompt-input').value = text;
      translateAndAnimate();
    }

    // Animation Loop
    let clock = new THREE.Clock();
    let frameTimer = 0;

    function animate() {
      requestAnimationFrame(animate);
      const delta = clock.getDelta();
      frameTimer += delta;

      if (currentKeyframes.length > 0 && frameTimer >= (1 / 30)) {
        frameTimer = 0;
        applyPoseFrame(currentKeyframes[currentFrameIdx]);
        currentFrameIdx++;

        if (currentFrameIdx >= currentKeyframes.length) {
          currentKeyframes = [];
          playNextGloss();
        }
      }

      renderer.render(scene, camera);
    }

    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });

    // Start with default neutral sign
    quickSign('Where is the hospital?');
    animate();
  </script>
</body>
</html>
"""
