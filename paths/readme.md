1. cat.svg is the demo image for svg_to_path.py (SVG from https://freesvg.org/cat-silhouette-vector)
2. polynomial_reg_lut.py takes a .CSV, creates a 2nd degree polynomial regression model, and outputs a lookup table in 0.5mm increments
3. polynomial_reg_servo.py was the basis of polynomial_reg_lut.py
4. svg_to_path.py takes a .SVG, samples points around its edge, and converts those points to an array of servo positions based on the LUT from above.
5. lookup_table.csv is the output from polynomail_reg_lut.py (from 3/3/25)
6. cartesian.csv contains the sampled points from 3/2/35
