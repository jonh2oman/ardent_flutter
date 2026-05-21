
def check_braces(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    stack = []
    for i, line in enumerate(lines):
        for char in line:
            if char == '{':
                stack.append(i + 1)
            elif char == '}':
                if not stack:
                    print(f"Extra closing brace at line {i + 1}")
                else:
                    stack.pop()
    
    if stack:
        for line_num in stack:
            print(f"Opening brace at line {line_num} never closed")
    else:
        print("Braces are balanced")

check_braces('/Users/jonathanwaterman/Antigravity/ardent_flutter/lib/screens/cadet_detail_screen.dart')
