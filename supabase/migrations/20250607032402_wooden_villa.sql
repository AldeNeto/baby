/*
  # Mundo Kids E-commerce Database Schema

  1. New Tables
    - `categories`
      - `id` (uuid, primary key)
      - `name` (text)
      - `color_theme` (text) - 'pink' or 'blue'
      - `created_at` (timestamp)
    
    - `products`
      - `id` (uuid, primary key)
      - `name` (text)
      - `description` (text)
      - `price` (decimal)
      - `image_url` (text)
      - `category_id` (uuid, foreign key)
      - `stock_quantity` (integer)
      - `age_range` (text)
      - `created_at` (timestamp)
    
    - `cart_items`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `product_id` (uuid, foreign key)
      - `quantity` (integer)
      - `created_at` (timestamp)
    
    - `orders`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `total_amount` (decimal)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `order_items`
      - `id` (uuid, primary key)
      - `order_id` (uuid, foreign key)
      - `product_id` (uuid, foreign key)
      - `quantity` (integer)
      - `price` (decimal)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
    - Public read access for products and categories
*/

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  color_theme text NOT NULL CHECK (color_theme IN ('pink', 'blue', 'neutral')),
  created_at timestamptz DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  price decimal(10,2) NOT NULL,
  image_url text DEFAULT '',
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  stock_quantity integer DEFAULT 0,
  age_range text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- Cart items table
CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  total_amount decimal(10,2) NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1,
  price decimal(10,2) NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Categories policies (public read)
CREATE POLICY "Categories are viewable by everyone"
  ON categories FOR SELECT
  TO anon, authenticated
  USING (true);

-- Products policies (public read)
CREATE POLICY "Products are viewable by everyone"
  ON products FOR SELECT
  TO anon, authenticated
  USING (true);

-- Cart items policies (user-specific)
CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Orders policies (user-specific)
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Order items policies (user can view items from their orders)
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (EXISTS (
    SELECT 1 FROM orders 
    WHERE orders.id = order_items.order_id 
    AND orders.user_id = auth.uid()
  ));

CREATE POLICY "Users can create order items for own orders"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM orders 
    WHERE orders.id = order_items.order_id 
    AND orders.user_id = auth.uid()
  ));

-- Insert sample categories
INSERT INTO categories (name, color_theme) VALUES
  ('Meninas', 'pink'),
  ('Meninos', 'blue'),
  ('Bebês', 'neutral'),
  ('Brinquedos', 'neutral');

-- Insert sample products
INSERT INTO products (name, description, price, image_url, category_id, stock_quantity, age_range) VALUES
  ('Vestido Princesa Rosa', 'Lindo vestido rosa com detalhes em renda', 45.90, 'https://images.pexels.com/photos/8088495/pexels-photo-8088495.jpeg', (SELECT id FROM categories WHERE name = 'Meninas'), 15, '3-8 anos'),
  ('Camiseta Super Herói', 'Camiseta azul com estampa de super herói', 29.90, 'https://images.pexels.com/photos/8419086/pexels-photo-8419086.jpeg', (SELECT id FROM categories WHERE name = 'Meninos'), 20, '4-10 anos'),
  ('Body Bebê Unicórnio', 'Body macio com estampa de unicórnio', 19.90, 'https://images.pexels.com/photos/8088134/pexels-photo-8088134.jpeg', (SELECT id FROM categories WHERE name = 'Bebês'), 25, '0-12 meses'),
  ('Boneca Fashion', 'Boneca com roupinhas e acessórios', 79.90, 'https://images.pexels.com/photos/8088188/pexels-photo-8088188.jpeg', (SELECT id FROM categories WHERE name = 'Brinquedos'), 10, '3-10 anos'),
  ('Carrinho de Controle', 'Carrinho azul com controle remoto', 89.90, 'https://images.pexels.com/photos/163064/play-stone-network-networked-interactive-163064.jpeg', (SELECT id FROM categories WHERE name = 'Brinquedos'), 8, '5-12 anos'),
  ('Sapatinho Rosa', 'Sapatinho confortável para meninas', 35.90, 'https://images.pexels.com/photos/8088495/pexels-photo-8088495.jpeg', (SELECT id FROM categories WHERE name = 'Meninas'), 12, '1-5 anos');