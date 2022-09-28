import logging
import argparse
import os.path
import ntpath

# Constants
kVTX = 0
kIDX = 1
kPositionX = "POSITION0.x"
kPositionY = "POSITION0.y"
kPositionZ = "POSITION0.z"
kSVPositionX = "SV_POSITION.x"
kSVPositionY = "SV_POSITION.y"
kSVPositionZ = "SV_POSITION.z"
kUV0X = "TEXCOORD0.x"
kUV0Y = "TEXCOORD0.y"
kNormalX = "NORMAL0.x"
kNormalY = "NORMAL0.y"
kNormalZ = "NORMAL0.z"


def build_vert_map(vertex_vals_array):
    vert_ids = []
    vert_map = []

    for v_val in vertex_vals_array:
        v_idx = v_val[kIDX]

        if v_idx not in vert_ids:
            vert_ids.append(v_idx)
            vert_map.append(v_val)

    sorted(vert_map, key=lambda x: x[kIDX])

    return vert_map


def get_position_data(vert, header_values):
    if kPositionX in header_values:
        return (vert[header_values.index(kPositionX)],
                vert[header_values.index(kPositionY)],
                vert[header_values.index(kPositionZ)])
    elif kSVPositionX in header_values:
        logging.warning("Screen space positions found, you probably did not want to save out this part of the shader?")
        return (vert[header_values.index(kSVPositionX)],
                vert[header_values.index(kSVPositionY)],
                vert[header_values.index(kSVPositionZ)])
    else:
        logging.error("No positional data found")
        return None


def get_uv_data(vert, header_values):
    if kUV0X in header_values:
        return (vert[header_values.index(kUV0X)],
                vert[header_values.index(kUV0Y)])
    else:
        logging.warning("No uv data found")
        return None


def get_normal_data(vert, header_values):
    if kNormalX in header_values:
        return (vert[header_values.index(kNormalX)],
                vert[header_values.index(kNormalY)],
                vert[header_values.index(kNormalZ)])
    else:
        logging.warning("No normal data found")
        return None


def export_output(vert_map, tri_array, header_values, output_path, output_name):
    output = ""
    output += "# Generated CSV 2 OBJ Mesh\n"

    # Write out vertex positions
    for vert in vert_map:
        pos = get_position_data(vert, header_values)
        if pos is not None:
            output += f"v {pos[0]} {pos[1]} {pos[2]}\n"

    # Write out UV0
    for vert in vert_map:
        uv = get_uv_data(vert, header_values)
        if uv is not None:
            output += f"vt {uv[0]} {uv[1]}\n"

    # Write out vertex normals
    for vert in vert_map:
        normal = get_normal_data(vert, header_values)
        if normal is not None:
            output += f"vn {normal[0]} {normal[1]} {normal[2]}\n"

    # Write out faces
    i = 0
    while i < len(tri_array):
        v1 = "{0}/{0}/{0}".format(str(int(tri_array[i]) + 1))
        v2 = "{0}/{0}/{0}".format(str(int(tri_array[i+1]) + 1))
        v3 = "{0}/{0}/{0}".format(str(int(tri_array[i+2]) + 1))
        output += f"f {v1} {v2} {v3}\n"
        i += 3

    output_file = open(f"{output_path}\\{output_name}.obj", "w")
    output_file.write(output)
    output_file.close()
    logging.info(f"Successfully wrote file to {output_path}\\{output_name}.obj")


def parse_csv(csv_path, output_path, output_name):
    with open(csv_path, 'r') as csv_file:

        # Get header if needed for anything
        header_line = csv_file.readline()
        header_values = header_line.split(",")
        header_values = [val.strip() for val in header_values]

        # Get vertex attributes
        vertex_vals_array = []
        for line in csv_file:
            values = line.split(",")
            values = [val.strip() for val in values]
            vertex_vals_array.append(values)

        # Build vert map
        vert_map = build_vert_map(vertex_vals_array)

        # Build tri array
        tri_array = [val[kIDX] for val in vertex_vals_array]

        # Make output file
        export_output(vert_map, tri_array, header_values, output_path, output_name)


if __name__ == '__main__':
    # Set up logging
    logging_level = logging.DEBUG
    logging_format = '[%(levelname)s] %(asctime)s - %(message)s'
    logging.basicConfig(level=logging_level, format=logging_format)

    # Parse input
    parser = argparse.ArgumentParser(description='Optional app description')
    parser.add_argument('file_path', type=str, help='Filepath to input .csv file')
    parser.add_argument('--out_name', type=str, help='Output .obj name')
    args = parser.parse_args()

    # Validate
    if not os.path.isfile(args.file_path):
        parser.error("Given input file does not exist")
    if not args.file_path.endswith(".csv"):
        parser.error("Given input file was not a .csv")

    head, tail = ntpath.split(args.file_path)
    output_dir = head
    output_name = tail.split(".")[0]

    if args.out_name is not None:
        output_name = args.out_name

    parse_csv(args.file_path, output_dir, output_name)
