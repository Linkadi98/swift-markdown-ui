#!/usr/bin/env python3
"""
Script to add @available(iOS 15.0, *) annotations to Swift declarations.
This helps convert from minimum iOS target to availability markup usage.
"""

import os
import re
import argparse
import fnmatch

def find_swift_files(directory, exclude_patterns=None):
    """Find all Swift files in the directory, excluding specified patterns."""
    swift_files = []
    exclude_patterns = exclude_patterns or []
    
    for root, dirs, files in os.walk(directory):
        # Skip hidden directories and common build directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['build', 'DerivedData']]
        
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, directory)
                
                # Check if file should be excluded
                should_exclude = False
                for pattern in exclude_patterns:
                    if fnmatch.fnmatch(relative_path, pattern):
                        should_exclude = True
                        break
                
                if not should_exclude:
                    swift_files.append(file_path)
    
    return swift_files

def should_add_availability(content, line_num, lines):
    """Check if we should add availability annotation based on context."""
    current_line = lines[line_num].strip()
    
    # Skip if already has @available annotation above
    if line_num > 0:
        prev_line = lines[line_num - 1].strip()
        if prev_line.startswith('@available'):
            return False
    
    # Skip if it's inside another declaration (check indentation)
    current_indent = len(lines[line_num]) - len(lines[line_num].lstrip())
    if current_indent > 0:
        return False
    
    # Skip protocol conformance extensions (they usually don't need availability)
    if 'extension' in current_line and ':' in current_line:
        # Check if it's a simple protocol conformance
        if re.search(r'extension\s+\w+\s*:\s*\w+', current_line):
            return False
    
    # Skip if it's a simple wrapper or doesn't use iOS 15+ APIs
    # (This would require more sophisticated analysis, keeping simple for now)
    
    return True

def add_availability_annotations(file_path, ios_version="15.0", dry_run=False):
    """Add @available annotations to Swift declarations in the file."""
    
    # Patterns to match declarations that should get availability annotations
    declaration_patterns = [
        # struct declarations
        r'^(public\s+struct\s+)',
        r'^(private\s+struct\s+)',
        r'^(internal\s+struct\s+)',
        r'^(struct\s+)',
        r'^(@frozen\s+public\s+struct\s+)',
        r'^(@frozen\s+struct\s+)',
        
        # enum declarations
        r'^(public\s+enum\s+)',
        r'^(private\s+enum\s+)',
        r'^(internal\s+enum\s+)',
        r'^(enum\s+)',
        r'^(@frozen\s+public\s+enum\s+)',
        r'^(@frozen\s+enum\s+)',
        
        # enum with attributes like @resultBuilder
        r'^(@\w+\s+public\s+enum\s+)',
        r'^(@\w+\s+enum\s+)',
        r'^(@\w+\s+@\w+\s+public\s+enum\s+)',
        r'^(@\w+\s+@\w+\s+enum\s+)',
        
        # class declarations
        r'^(public\s+class\s+)',
        r'^(private\s+class\s+)',
        r'^(internal\s+class\s+)',
        r'^(class\s+)',
        r'^(final\s+public\s+class\s+)',
        r'^(final\s+class\s+)',
        r'^(@\w+\s+public\s+class\s+)',
        r'^(@\w+\s+class\s+)',
        
        # actor declarations (iOS 15+)
        r'^(public\s+actor\s+)',
        r'^(private\s+actor\s+)',
        r'^(internal\s+actor\s+)',
        r'^(actor\s+)',
        
        # protocol declarations
        r'^(public\s+protocol\s+)',
        r'^(private\s+protocol\s+)',
        r'^(internal\s+protocol\s+)',
        r'^(protocol\s+)',
        
        # extension declarations
        r'^(public\s+extension\s+)',
        r'^(private\s+extension\s+)',
        r'^(internal\s+extension\s+)',
        r'^(extension\s+)',
    ]
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        lines = content.split('\n')
        modified_lines = []
        changes_made = 0
        
        i = 0
        while i < len(lines):
            line = lines[i]
            line_matched = False
            
            # Check each pattern
            for pattern in declaration_patterns:
                if re.match(pattern, line.strip()):
                    if should_add_availability(content, i, lines):
                        # Get the indentation of the current line
                        indent = line[:len(line) - len(line.lstrip())]
                        
                        # Add the @available annotation with same indentation
                        availability_annotation = f"{indent}@available(iOS {ios_version}, macOS 12.0, tvOS {ios_version}, watchOS 8.0, *)"
                        modified_lines.append(availability_annotation)
                        modified_lines.append(line)
                        changes_made += 1
                        line_matched = True
                        print(f"  Added @available to: {line.strip()}")
                        break
            
            if not line_matched:
                modified_lines.append(line)
            
            i += 1
        
        if changes_made > 0 and not dry_run:
            # Write the modified content back to file
            new_content = '\n'.join(modified_lines)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"✅ Modified {file_path} - added {changes_made} @available annotations")
            return changes_made
        elif changes_made > 0:
            print(f"🔍 Would modify {file_path} - {changes_made} @available annotations")
            return changes_made
        else:
            print(f"⚪ No changes needed for {file_path}")
            return 0
            
    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return 0

def main():
    parser = argparse.ArgumentParser(
        description='Add @available(iOS 15.0, *) annotations to Swift declarations'
    )
    parser.add_argument(
        'directory', 
        help='Directory containing Swift files to process'
    )
    parser.add_argument(
        '--ios-version', 
        default='15.0',
        help='iOS version for availability annotation (default: 15.0)'
    )
    parser.add_argument(
        '--dry-run', 
        action='store_true',
        help='Show what would be changed without making actual changes'
    )
    parser.add_argument(
        '--exclude',
        action='append',
        default=[],
        help='Exclude files matching this pattern (can be used multiple times)'
    )
    parser.add_argument(
        '--include-tests',
        action='store_true',
        help='Include test files (excluded by default)'
    )
    
    args = parser.parse_args()
    
    # Default exclusions
    exclude_patterns = args.exclude.copy()
    if not args.include_tests:
        exclude_patterns.extend(['*Test*.swift', '**/Tests/**', '**/test/**'])
    
    print(f"🔍 Scanning for Swift files in: {args.directory}")
    if exclude_patterns:
        print(f"📝 Excluding patterns: {exclude_patterns}")
    
    swift_files = find_swift_files(args.directory, exclude_patterns)
    
    print(f"📁 Found {len(swift_files)} Swift files to process")
    
    if args.dry_run:
        print("🔍 DRY RUN MODE - No files will be modified")
    
    total_changes = 0
    processed_files = 0
    
    for file_path in swift_files:
        print(f"\n📄 Processing: {os.path.relpath(file_path, args.directory)}")
        changes = add_availability_annotations(file_path, args.ios_version, args.dry_run)
        total_changes += changes
        if changes > 0:
            processed_files += 1
    
    print(f"\n🎉 Summary:")
    print(f"   📁 Total files scanned: {len(swift_files)}")
    print(f"   ✏️  Files modified: {processed_files}")
    print(f"   🔧 Total annotations added: {total_changes}")
    
    if args.dry_run:
        print("\n💡 Run without --dry-run to apply changes")

if __name__ == "__main__":
    main()