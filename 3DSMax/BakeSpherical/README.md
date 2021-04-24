Bakes spherical coordinates of the 3D mesh to a specific vertex channel. Useful for reading this data in a shader to produce visual effects.

The coordinates are defined where

x = r * cos(phi) * sin(theta)
y = r * sin(phi) * sin(theta)
z = r * cos(theta)

r is baked to the .x coordinate of the vertex channel
theta is baked to the .y coordinate of the vertex channel
phi is baked to the .z coordinate of the vertex channel

theta is in the range [0, PI]
phi is in the range [0, 2 * PI]

theta and phi are saved as radians

Relative To:

-> Object Pivot : Calculates rotation around axis relative to the object's pivot

-> World Origin : Calculates rotation around axis relative to the point [0, 0, 0]

-> Object Center of Mass : Calculates rotation around axis relative to average vertex position. Not technically the "center of mass" but good enough for a quick bake. If more control is needed then one of the other options is a better fit.

-> Target Object : Calculates rotation around axis relative to the target object's pivot

Vertex Channel:

-> The vertex channel the spherical coordinates will be baked to.

Visualize Object in Vertex Color:

-> Remaps the coordinates to (0-255) and saves the result in the vertex color. Useful for checking if the result is what you expect.

![image](https://user-images.githubusercontent.com/16472643/115941625-23e05c80-a474-11eb-9f15-58f60b955cf9.png)
