#!/bin/bash

# Base directory for blog posts
POST_BASE_DIR="./content/post"

echo "--- Hugo Blog Post Management ---"
echo "Enter the title or slug of the blog post you want to manage:"
read BLOG_IDENTIFIER

# Convert input to slug format (lowercase, replace spaces with hyphens)
# This makes the script more flexible, allowing the user to enter the full title
# as well as the slug. It also cleans up non-alphanumeric characters for slug generation.
SLUG=$(echo "$BLOG_IDENTIFIER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

POST_DIR="$POST_BASE_DIR/$SLUG"
INDEX_MD_FILE="$POST_DIR/index.md"

# Check if the post directory exists
if [ ! -d "$POST_DIR" ]; then
    echo "Error: Blog post directory not found at '$POST_DIR'."
    echo "Please ensure you entered the correct title or slug (e.g., 'sample' or 'My Sample Post')."
    exit 1
fi

echo "Found blog post: '$SLUG' (Path: '$INDEX_MD_FILE')"
echo ""
echo "What would you like to do?"
echo "1. Change status to DRAFT (hide from the public site)"
echo "2. Permanently DELETE the blog post"
echo "3. Cancel operation"

read -p "Enter your choice (1, 2, or 3): " choice

case $choice in
    1)
        if [ -f "$INDEX_MD_FILE" ]; then
            # Use Perl for cross-platform in-place editing of the draft status
            # This command finds the 'draft:' line and ensures its value is 'true'.
            # It handles cases where draft might be 'false' or not present.
            # If 'draft:' is not found, it won't add it, relying on 'add_blog.sh'
            # to always include it for new posts.
            perl -pi -e 's/^(draft: ).*$/$1true/' "$INDEX_MD_FILE"
            echo "Success: Blog post '$SLUG' set to DRAFT."
            echo "Remember to restart your Hugo server to apply changes if running locally."
        else
            echo "Error: '$INDEX_MD_FILE' not found for post '$SLUG'."
            echo "Cannot change draft status. Please check the contents of '$POST_DIR' manually."
        fi
        ;;
    2)
        read -p "WARNING: You are about to PERMANENTLY DELETE the blog post '$SLUG' and its entire directory '$POST_DIR'. This action cannot be undone. Are you absolutely sure? (yes/no): " confirm_delete
        if [[ "$confirm_delete" == "yes" ]]; then
            rm -rf "$POST_DIR"
            echo "Success: Blog post '$SLUG' and its directory permanently deleted."
            echo "Remember to restart your Hugo server to apply changes if running locally."
        else
            echo "Operation cancelled: Blog post was NOT deleted."
        fi
        ;;
    3)
        echo "Operation cancelled."
        ;;
    *)
        echo "Invalid choice. Please enter 1, 2, or 3."
        echo "Operation cancelled."
        ;;
esac