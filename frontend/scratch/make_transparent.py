from PIL import Image
from collections import deque

img = Image.open('d:/Ourly-App/frontend/assets/images/couple_illustration.png').convert('RGBA')
width, height = img.size
pixels = img.load()

visited = [[False]*height for _ in range(width)]
queue = deque()

# Add all edge pixels
for x in range(width):
    queue.append((x, 0))
    queue.append((x, height - 1))
for y in range(height):
    queue.append((0, y))
    queue.append((width - 1, y))

def is_background(r, g, b):
    # Check if pixel is white/off-white background
    # Background in this image is very pale: min(r,g,b) > 235 and diffs are small
    return min(r, g, b) >= 238 and max(r, g, b) - min(r, g, b) <= 18

while queue:
    x, y = queue.popleft()
    if visited[x][y]:
        continue
    visited[x][y] = True
    
    r, g, b, a = pixels[x, y]
    if is_background(r, g, b):
        b_val = min(r, g, b)
        if b_val >= 248:
            pixels[x, y] = (r, g, b, 0)
        else:
            # smooth feathering
            alpha = int(255 * (248 - b_val) / 10.0)
            pixels[x, y] = (r, g, b, max(0, min(255, alpha)))
            
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < width and 0 <= ny < height and not visited[nx][ny]:
                queue.append((nx, ny))

img.save('d:/Ourly-App/frontend/assets/images/couple_illustration_transparent.png')
print("Successfully generated couple_illustration_transparent.png with clean edges!")
