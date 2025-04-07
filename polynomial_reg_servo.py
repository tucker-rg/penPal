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

# Example usage
x_test, y_test = 12, 4
predicted_positions = predict_servo_positions(x_test, y_test)
print(f"Predicted servo positions for ({x_test}, {y_test}): {predicted_positions}")
