import pandas as pd
import numpy as np
import cv2
import svgpathtools
from svgpathtools import svg2paths, Path, wsvg
from scipy.spatial import KDTree

lookup_df = pd.read_csv("lookup_table.csv")
lookup_points = lookup_df[["X", "Y"]].values
servo_positions = lookup_df[["servo_0", "servo_1", "servo_2"]].values
# Create a KDTree for fast nearest-neighbor lookup
lookup_tree = KDTree(lookup_points)

# Function to find nearest servo positions
def get_servo_positions(x, y):
    _, index = lookup_tree.query([x, y])
    return tuple(servo_positions[index])

# Function to process SVG and extract paths
def normalize_coordinates(coordinates, target_min=-10.0, target_max=10.0):
    coords = np.array(coordinates, dtype=float)  # Ensure array of floats
    
    # Find min and max of extracted coordinates
    x_min, x_max = coords[:, 0].min(), coords[:, 0].max()
    y_min, y_max = coords[:, 1].min(), coords[:, 1].max()
    
    # Normalize function (maps [old_min, old_max] -> [target_min, target_max])
    def scale(val, old_min, old_max, new_min, new_max):
        return float(new_min + (val - old_min) * (new_max - new_min) / (old_max - old_min))

    # Apply normalization
    norm_coords = [(scale(x, x_min, x_max, target_min, target_max), 
                    scale(y, y_min, y_max, target_min, target_max)) 
                   for x, y in coordinates]
    
    return norm_coords

# Modify extract_svg_paths to apply normalization
# def extract_svg_paths(svg_file):
#     paths, _ = svgpathtools.svg2paths(svg_file)
#     coordinates = []
#     for path in paths:
#         wsvg([path], filename='kitten_path.svg')
#         for i in np.linspace(0, 1, num=100):  # Sample points along the path
#             point = path.point(i)
#             coordinates.append((float(point.real), float(point.imag)))  # Ensure float conversion

# This version samples 3 points from each segment of the path
def extract_svg_paths(svg_file):
    paths, _ = svg2paths(svg_file)
    coordinates = []

    for path in paths:
        wsvg([path], filename='kitten_path.svg')  # Optional visualization
        for segment in path:  # Each segment is a curve (Line, CubicBezier, etc.)
            for t in [0.0, 0.5, 1.0]:  # Sample 3 points per segment
                point = segment.point(t)
                coordinates.append((float(point.real), float(point.imag)))  # Ensure float conversion

    # Normalize coordinates to fit within lookup table range
    return normalize_coordinates(coordinates)

'''
# Function to process an image and extract contours
def extract_image_paths(image_file):
    image = cv2.imread(image_file, cv2.IMREAD_GRAYSCALE)
    _, thresh = cv2.threshold(image, 127, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    coordinates = [tuple(pt[0]) for contour in contours for pt in contour]
    return coordinates
'''

# Function to generate servo motion path from coordinates
def generate_motion_path(coordinates):
    motion_path = [get_servo_positions(x, y) for x, y in coordinates]
    return motion_path

# Example usage
svg_file = "cat.svg"  # Replace with actual file
output_file = "kitten_segmentwise.txt" # Replace with desired output file
coordinates = extract_svg_paths(svg_file)

int_coords = []
for i in coordinates:
    temp_list = []
    for f in i:
        temp_list.append(round(f,1))
    int_coords.append(temp_list)
for i in int_coords:
    print(i[0])
print("spacer____________")
for i in int_coords:
    print(i[1])
 
motion_path = generate_motion_path(coordinates)
mod_motion = []
for i in motion_path:
    temp_list = []
    for f in i:
        temp_list.append(int(f))
    mod_motion.append(temp_list)
    
print("Generated Servo Motion Path:")
print("length: ", len(mod_motion))

# Convert each sublist to a string with {} formatting
formatted = [f"{{{x}, {y}, {z}}}" for x, y, z in mod_motion]

# Break into chunks of 8
lines = [', '.join(formatted[i:i+8]) for i in range(0, len(formatted), 8)]

# Join lines with line breaks and wrap in outer braces
final_string = "{" + ",".join(lines) + "}"

with open(output_file, "w") as f:
    f.write(final_string)