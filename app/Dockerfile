# Use nginx alpine as base image
FROM nginx:alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy assets folder with HTML and images
COPY assets/ /usr/share/nginx/html/

# Copy HTML as template for environment variable substitution
RUN mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.template

# Set default environment variable
ENV USER_NAME="Ahmad Afif"

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose port 80
EXPOSE 80

# Use custom startup script
CMD ["/start.sh"]
