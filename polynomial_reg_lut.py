import pandas as pd
import numpy as np
from sklearn.preprocessing import PolynomialFeatures
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import make_pipeline

# Load dataset
df = pd.read_csv("cartesian.csv")

# Prepare data
X = df[["X", "Y"]]
y_servo_0 = df["servo_0"]
y_servo_1 = df["servo_1"]
y_servo_2 = df["servo_2"]

# Train polynomial regression models (degree 2)
degree = 2
models = {}
for i, y in enumerate([y_servo_0, y_servo_1, y_servo_2]):
    model = make_pipeline(PolynomialFeatures(degree), LinearRegression())
    model.fit(X.values, y)
    models[i] = model

# Function to predict servo positions
def predict_servo_positions(x, y):
    input_point = np.array([[x, y]])
    s0 = models[0].predict(input_point)[0]
    s1 = models[1].predict(input_point)[0]
    s2 = models[2].predict(input_point)[0]
    return round(s0), round(s1), round(s2)

# Generate lookup table
x_range = np.arange(-12.5, 13, 0.5)  # Step size of 2.5mm
y_range = np.arange(-12.5, 13, 0.5)
lookup_table = []

for x in x_range:
    for y in y_range:
        s0, s1, s2 = predict_servo_positions(x, y)
        lookup_table.append([x, y, s0, s1, s2])

# Save lookup table to CSV
lookup_df = pd.DataFrame(lookup_table, columns=["X", "Y", "servo_0", "servo_1", "servo_2"])
lookup_df.to_csv("lookup_table.csv", index=False)

print("Lookup table generated and saved as 'lookup_table.csv'")
