FROM node:20-slim

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Vite dev server on 0.0.0.0:5173 and fail if port is taken
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173", "--strictPort"]