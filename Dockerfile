# --- Stage 1: The Builder ---
# This stage builds the React front-end and installs all dependencies.
FROM node:18-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker's layer caching.
# If these files don't change, Docker won't re-run 'npm install' on subsequent builds.
COPY package*.json ./

# Install all dependencies, including development dependencies needed for the build.
RUN npm install

# Copy the rest of the application source code into the container.
COPY . .

# Run the build script defined in package.json to create the optimized React app.
RUN npm run build


# --- Stage 2: The Production Image ---
# This stage creates the final, lightweight image.
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy package manifests again
COPY package*.json ./

# Install ONLY the production dependencies. We don't need the dev dependencies in the final image.
RUN npm install --production

# Copy the built React application and the Node.js server from the 'builder' stage.
# This is the magic of multi-stage builds.
COPY --from=builder /app/build ./build
COPY --from=builder /app/server ./server

# Tell Docker that the container will listen on port 3000 at runtime.
EXPOSE 3000

# The command to start the Node.js server when the container starts.
CMD ["node", "server/index.js"]