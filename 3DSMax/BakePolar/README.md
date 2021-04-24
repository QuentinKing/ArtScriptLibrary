Bakes polar coordinates of the 3D mesh to a specific vertex channel. Useful for reading this data in a shader to produce visual effects.

Calculated as:

- x = r * cos(theta)

- y = r * sin(theta)

- (Note that x and y varies due to what axis you bake around)

- The radius is baked into the .x coordiante of the vertex channel

- The theta is baked into the .y coordinate of the vertex channel

- Theta is in the range [0, 2PI] and is in radians


**Around Axis**

 -> Bakes the rotational angle around this axis


**Relative To:**

 -> Object Pivot : Calculates rotation around axis relative to the object's pivot
 
 -> World Origin : Calculates rotation around axis relative to the point [0, 0, 0]
 
 -> Object Center of Mass : Calculates rotation around axis relative to average vertex position. Not technically the "center of mass" but good enough for a quick bake. If more control is needed then one of the other options is a better fit.
 
 -> Target Object : Calculates rotation around axis relative to the target object's pivot
 
 
 **Vertex Channel:**
 
  -> The vertex channel the polar coordinates will be baked to. The rotation angle (theta) is saved in the x-coordinate with the range (0-2PI) and the radius is saved in the y-coordinate.
  
  
  **Visualize Object in Vertex Color:**
  
  -> Remaps the theta and radius to (0-255) and saves the result in the vertex color. Useful for checking if the result is what you expect.

![image](https://user-images.githubusercontent.com/16472643/115941720-9cdfb400-a474-11eb-9373-90f294843ea2.png)
