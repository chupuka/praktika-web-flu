// Учебное API «Мебельный магазин» для Supabase Edge Functions.
// Логика повторяет mock-server.js, меняется только транспорт.
import { Buffer } from 'node:buffer';
import crypto from 'node:crypto';
import postgres from 'npm:postgres@3.4.5';

const env = (name, fallback) => {
  try {
    return Deno.env.get(name) ?? fallback;
  } catch {
    return fallback;
  }
};

function arg(name, fallback) {
  return env('API_' + name.toUpperCase(), fallback);
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));
const DEFAULT_DELAY = Number(arg('delay', 0));
const REFRESH_TTL = 60 * 60 * 24 * 7;

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const parts = token.split('.');
  const body = parts[0];
  const mac = parts[1];
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

let db;

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function seed() {
  db = {
    seq: {},
    categories: [],
    manufacturers: [],
    materials: [],
    products: [],
    customers: [],
    users: [],
    refreshTokens: new Set(),
  };

  const C = (name, description) => push('categories', { name, description });
  const catSofas = C('Диваны и кресла', 'Мягкая мебель для гостиной и отдыха');
  const catTables = C('Столы и стулья', 'Обеденные и письменные столы, стулья');
  const catBeds = C('Кровати и матрасы', 'Спальная мебель и принадлежности');
  const catStorage = C('Шкафы и стеллажи', 'Системы хранения для дома');
  const catKitchen = C('Кухонная мебель', 'Гарнитуры и модули для кухни');
  const catHallway = C('Прихожие', 'Мебель для прихожей и коридора');
  const catChildren = C('Детская мебель', 'Мебель для детской комнаты');
  const catOffice = C('Офисная мебель', 'Мебель для кабинета и офиса');

  const M = (name, country, contactEmail) => push('manufacturers', { name, country, contactEmail });
  const ikea = M('IKEA', 'Швеция', 'info@ikea.com');
  const hoff = M('Hoff', 'Россия', 'shop@hoff.ru');
  const mrdoors = M('Mr.Doors', 'Россия', 'info@mrdoors.ru');
  const leroy = M('Leroy Merlin', 'Франция', 'service@leroymerlin.ru');
  const shatura = M('Шатура', 'Россия', 'office@shatura.ru');

  const T = (name, description) => push('materials', { name, description });
  const oak = T('Массив дуба', 'Натуральная древесина твёрдых пород');
  const mdf = T('МДФ', 'Древесноволокнистая плита');
  const lsp = T('ЛДСП', 'Ламинированная стружечная плита');
  const metal = T('Металл', 'Сталь и порошковая окраска');
  const eco = T('Экокожа', 'Искусственная кожа');
  const microfiber = T('Микрофибра', 'Синтетическая ворсовая ткань');
  const velvet = T('Велюр', 'Бархатистая обивочная ткань');
  const glass = T('Стекло', 'Закалённое стекло');

  const P = (
    name, sku, description, style, price, stock,
    width, depth, height, weight, color, categoryId, manufacturerId, materialIds
  ) => push('products', {
    name, sku, description, style, price, stock,
    width, depth, height, weight, color, categoryId, manufacturerId, materialIds,
  });

  P('Диван-кровать «Уют»', 'MB-001', 'Удобный диван-кровать с механизмом трансформации. Обивка — износостойкая микрофибра.', 'modern', 45990, 15, 200, 90, 85, 45, 'Серый', catSofas, hoff, [microfiber, metal]);
  P('Угловой диван «Лофт»', 'MB-002', 'Стильный угловой диван с местом для хранения внутри.', 'loft', 78990, 8, 260, 160, 80, 62, 'Чёрный', catSofas, mrdoors, [eco, metal]);
  P('Кресло «Релакс»', 'MB-003', 'Комфортное кресло с высокой спинкой. Механизм качания.', 'modern', 19990, 25, 75, 80, 110, 18, 'Тёмно-синий', catSofas, ikea, [velvet, metal]);
  P('Стол обеденный «Классика»', 'MB-004', 'Большой обеденный стол из массива дуба на 6 персон.', 'classic', 34990, 10, 180, 90, 75, 35, 'Дуб', catTables, shatura, [oak, metal]);
  P('Стул «Барселона»', 'MB-005', 'Элегантный стул с мягким сиденьем.', 'modern', 8490, 40, 50, 55, 85, 6, 'Белый', catTables, mrdoors, [eco, metal]);
  P('Стол письменный «Офис»', 'MB-006', 'Компактный письменный стол с выдвижными ящиками.', 'scandi', 15990, 20, 120, 60, 75, 22, 'Белый', catTables, ikea, [lsp, metal]);
  P('Кровать двуспальная «Престиж»', 'MB-007', 'Двуспальная кровать с мягким изголовьем 160x200.', 'classic', 52990, 5, 165, 210, 90, 55, 'Бежевый', catBeds, mrdoors, [eco, mdf]);
  P('Матрас ортопедический «Здоровье»', 'MB-008', 'Ортопедический матрас с независимыми пружинами.', 'modern', 24990, 12, 160, 200, 22, 25, 'Белый', catBeds, hoff, [microfiber, metal]);
  P('Тумба прикроватная «Норд»', 'MB-009', 'Компактная прикроватная тумба с ящиком.', 'scandi', 6990, 30, 40, 35, 55, 8, 'Белый', catBeds, ikea, [mdf]);
  P('Шкаф-купе «Гранд»', 'MB-010', 'Вместительный шкаф-купе: полки, штанги, ящики.', 'modern', 68990, 7, 240, 60, 240, 90, 'Венге', catStorage, shatura, [lsp, glass]);
  P('Стеллаж «Открытый»', 'MB-011', 'Стеллаж с открытыми полками. Регулируемые полки.', 'scandi', 12490, 18, 80, 35, 200, 15, 'Дуб', catStorage, ikea, [lsp, metal]);
  P('Стенка гостиная «Модерн»', 'MB-012', 'Модульная стенка: шкаф, витрина, тумба под ТВ.', 'modern', 84900, 4, 300, 50, 220, 120, 'Орех', catStorage, hoff, [mdf, glass]);
  P('Кухонный гарнитур «Прованс»', 'MB-013', 'Классический кухонный гарнитур, 6 модулей.', 'provence', 189990, 3, 280, 60, 210, 150, 'Кремовый', catKitchen, mrdoors, [mdf, oak]);
  P('Кухонный уголок «Завтрак»', 'MB-014', 'Мягкий кухонный уголок с ящиком для хранения.', 'classic', 28990, 14, 140, 120, 85, 35, 'Коричневый', catKitchen, shatura, [eco, mdf]);
  P('Вешалка прихожая «Минимал»', 'MB-015', 'Настенная вешалка с полкой и крючками.', 'scandi', 3990, 50, 60, 25, 40, 4, 'Белый', catHallway, ikea, [metal, mdf]);
  P('Консоль прихожая «Элегант»', 'MB-016', 'Узкая консоль с ящиками и зеркалом.', 'classic', 18990, 10, 80, 40, 90, 18, 'Дуб', catHallway, hoff, [mdf, glass]);
  P('Кровать детская «Малыш»', 'MB-017', 'Детская кровать с бортиками 90x180. Безопасные углы.', 'scandi', 18990, 11, 95, 185, 70, 20, 'Белый', catChildren, ikea, [mdf, metal]);
  P('Стол детский «Школьник»', 'MB-018', 'Растущий письменный стол с регулировкой высоты.', 'modern', 12990, 16, 100, 60, 75, 16, 'Серый', catChildren, hoff, [lsp, metal]);
  P('Кресло офисное «Босс»', 'MB-019', 'Эргономичное кресло с поддержкой поясницы.', 'modern', 24990, 9, 65, 65, 130, 15, 'Чёрный', catOffice, mrdoors, [eco, metal]);
  P('Стеллаж офисный «Архив»', 'MB-020', 'Металлический стеллаж для документов.', 'loft', 21490, 13, 100, 40, 200, 28, 'Серый', catOffice, shatura, [metal, lsp]);
  P('Комод «Классик»', 'MB-021', 'Комод с пятью ящиками на направляющих.', 'classic', 27990, 6, 120, 45, 90, 32, 'Орех', catStorage, shatura, [mdf, oak]);
  P('Пуф «Мягкий»', 'MB-022', 'Круглый пуф с отделением для хранения.', 'modern', 5990, 0, 45, 45, 40, 5, 'Горчичный', catSofas, ikea, [velvet]);

  const customers = [
    ['Иванова Мария Петровна', 'kreslo.ivanovna@gmail.com', '+7 900 111-22-33', 'Москва, ул. Тверская, д. 12, кв. 5', { number: 'CL-1001', issuedAt: '2024-03-15', tier: 'gold', points: 1240 }],
    ['Петров Алексей Ильич', 'divan.petrovich@gmail.com', '+7 901 222-33-44', 'Санкт-Петербург, Невский пр., д. 88', { number: 'CL-1002', issuedAt: '2024-07-02', tier: 'silver', points: 430 }],
    ['Соколова Ольга Викторовна', 'polochka.olga@gmail.com', '+7 902 333-44-55', 'Казань, ул. Баумана, д. 40', null],
    ['Кузнецов Дмитрий Сергеевич', 'shkaf.kuznecov@gmail.com', '+7 903 444-55-66', 'Новосибирск, ул. Ленина, д. 7', { number: 'CL-1003', issuedAt: '2025-01-20', tier: 'basic', points: 85 }],
    ['Николаева Екатерина Андреевна', 'taburetka.kate@gmail.com', '+7 904 555-66-77', 'Екатеринбург, ул. Малышева, д. 101', null],
  ];

  for (const [fullName, email, phone, address, card] of customers) {
    push('customers', { fullName, email, phone, address, card });
  }

  push('users', { username: 'admin', passwordHash: hash('admin123'), fullName: 'Администратор', email: 'admin.za.divan@gmail.com', role: 'admin', customerId: null });
  push('users', { username: 'manager', passwordHash: hash('manager123'), fullName: 'Менеджер Бортников А. П.', email: 'menedzher.polok@gmail.com', role: 'manager', customerId: null });
  push('users', { username: 'customer', passwordHash: hash('customer123'), fullName: 'Иванова Мария Петровна', email: 'kreslo.ivanovna@gmail.com', role: 'customer', customerId: 1 });
}

function slimCategory(id) {
  const c = db.categories.find((x) => x.id === id);
  return c ? { id: c.id, name: c.name } : null;
}

function slimManufacturer(id) {
  const m = db.manufacturers.find((x) => x.id === id);
  return m ? { id: m.id, name: m.name } : null;
}

function expandProduct(p) {
  return {
    id: p.id,
    name: p.name,
    sku: p.sku,
    description: p.description,
    style: p.style,
    price: p.price,
    stock: p.stock,
    width: p.width,
    depth: p.depth,
    height: p.height,
    weight: p.weight,
    color: p.color,
    categoryId: p.categoryId,
    manufacturerId: p.manufacturerId,
    materialIds: p.materialIds,
    category: slimCategory(p.categoryId),
    manufacturer: slimManufacturer(p.manufacturerId),
    materials: p.materialIds
      .map((id) => db.materials.find((m) => m.id === id))
      .filter(Boolean)
      .map((m) => ({ id: m.id, name: m.name })),
    createdAt: p.createdAt,
    deletedAt: p.deletedAt,
  };
}

function expandCustomer(c) {
  return {
    id: c.id,
    fullName: c.fullName,
    email: c.email,
    phone: c.phone,
    address: c.address,
    card: c.card
      ? {
          number: c.card.number,
          issuedAt: c.card.issuedAt,
          tier: c.card.tier,
          points: c.card.points,
        }
      : null,
    createdAt: c.createdAt,
    deletedAt: c.deletedAt,
  };
}

function expandUser(u) {
  return {
    id: u.id,
    username: u.username,
    fullName: u.fullName,
    email: u.email,
    role: u.role,
    customerId: u.customerId,
  };
}

const EXPANDERS = {
  products: expandProduct,
  customers: expandCustomer,
  categories: (c) => c,
  manufacturers: (m) => m,
  materials: (m) => m,
};

function searchableText(collection, item) {
  switch (collection) {
    case 'products':
      return [item.name, item.sku, item.description, item.color].join(' ');
    case 'categories':
      return [item.name, item.description].join(' ');
    case 'manufacturers':
      return [item.name, item.country].join(' ');
    case 'materials':
      return [item.name, item.description].join(' ');
    case 'customers':
      return [item.fullName, item.email, item.phone].join(' ');
    default:
      return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) =>
      searchableText(collection, x).toLowerCase().includes(needle)
    );
  }

  if (collection === 'products') {
    if (q.categoryId) {
      result = result.filter((p) => p.categoryId === Number(q.categoryId));
    }
    if (q.manufacturerId) {
      result = result.filter(
        (p) => p.manufacturerId === Number(q.manufacturerId)
      );
    }
    if (q.priceFrom) {
      result = result.filter((p) => p.price >= Number(q.priceFrom));
    }
    if (q.priceTo) {
      result = result.filter((p) => p.price <= Number(q.priceTo));
    }
    if (q.style) {
      result = result.filter((p) => p.style === q.style);
    }
    if (q.inStock === '1') {
      result = result.filter((p) => p.stock > 0);
    }
  }

  if (collection === 'customers') {
    if (q.tier) {
      result = result.filter(
        (c) => c.card && c.card.tier === q.tier
      );
    }
  }

  return result;
}

function sortValue(collection, row, field) {
  if (collection === 'customers' && field === 'points') {
    return row.card ? row.card.points : 0;
  }
  return row[field];
}

function applySort(collection, rows, sort) {
  if (!sort) return rows;
  const parts = String(sort).split(',');
  const field = parts[0];
  const dirRaw = parts[1] || 'asc';
  const dir = dirRaw.toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = sortValue(collection, a, field);
    const bv = sortValue(collection, b, field);
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') {
      return (av - bv) * dir;
    }
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  if (collection === 'products') {
    if (!str(body.name)) e.name = 'Укажите название товара';
    else if (str(body.name).length > 120) e.name = 'Не длиннее 120 символов';

    if (!str(body.sku)) e.sku = 'Укажите артикул';
    else {
      const dup = db.products.find(
        (p) => p.sku.toLowerCase() === str(body.sku).toLowerCase() &&
          p.id !== id &&
          !p.deletedAt
      );
      if (dup) e.sku = 'Товар с таким артикулом уже существует';
    }

    const price = Number(body.price);
    if (!Number.isFinite(price) || price <= 0) {
      e.price = 'Цена — положительное число';
    } else if (price > 10000000) {
      e.price = 'Цена не может быть больше 10 000 000';
    }

    const stock = Number(body.stock);
    if (!Number.isInteger(stock) || stock < 0) {
      e.stock = 'Остаток — целое число не меньше нуля';
    }

    for (const key of ['width', 'depth', 'height', 'weight']) {
      const value = body[key];
      if (value == null || value === '') continue;
      const num = Number(value);
      if (!Number.isFinite(num) || num <= 0) {
        e[key] = 'Значение — положительное число';
      }
    }

    if (
      body.categoryId != null &&
      !db.categories.find(
        (c) => c.id === Number(body.categoryId) && !c.deletedAt
      )
    ) {
      e.categoryId = 'Категория не найдена';
    }

    if (
      body.manufacturerId != null &&
      !db.manufacturers.find(
        (m) => m.id === Number(body.manufacturerId) && !m.deletedAt
      )
    ) {
      e.manufacturerId = 'Производитель не найден';
    }

    if (body.materialIds != null) {
      const ids = Array.isArray(body.materialIds)
        ? body.materialIds.map(Number)
        : [];
      const bad = ids.find(
        (mid) => !db.materials.find((m) => m.id === mid && !m.deletedAt)
      );
      if (bad != null) e.materialIds = 'Материал не найден';
    }
  }

  if (collection === 'categories') {
    if (!str(body.name)) e.name = 'Укажите название категории';
    else {
      const dup = db.categories.find(
        (c) => c.name.toLowerCase() === str(body.name).toLowerCase() &&
          c.id !== id &&
          !c.deletedAt
      );
      if (dup) e.name = 'Такая категория уже существует';
    }
    if (str(body.description).length > 400) {
      e.description = 'Не длиннее 400 символов';
    }
  }

  if (collection === 'manufacturers') {
    if (!str(body.name)) e.name = 'Укажите название производителя';
    else {
      const dup = db.manufacturers.find(
        (m) => m.name.toLowerCase() === str(body.name).toLowerCase() &&
          m.id !== id &&
          !m.deletedAt
      );
      if (dup) e.name = 'Такой производитель уже существует';
    }
    if (!str(body.country)) e.country = 'Укажите страну';
    if (!str(body.contactEmail)) e.contactEmail = 'Укажите почту';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.contactEmail))) {
      e.contactEmail = 'Некорректный адрес почты';
    }
  }

  if (collection === 'materials') {
    if (!str(body.name)) e.name = 'Укажите название материала';
    else {
      const dup = db.materials.find(
        (m) => m.name.toLowerCase() === str(body.name).toLowerCase() &&
          m.id !== id &&
          !m.deletedAt
      );
      if (dup) e.name = 'Такой материал уже существует';
    }
    if (str(body.description).length > 400) {
      e.description = 'Не длиннее 400 символов';
    }
  }

  if (collection === 'customers') {
    if (!str(body.fullName)) e.fullName = 'Укажите ФИО покупателя';
    else if (str(body.fullName).length < 5) {
      e.fullName = 'Не короче пяти символов';
    }

    if (!str(body.email)) e.email = 'Укажите адрес почты';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.email))) {
      e.email = 'Некорректный адрес почты';
    } else {
      const dup = db.customers.find(
        (c) => c.email.toLowerCase() === str(body.email).toLowerCase() &&
          c.id !== id &&
          !c.deletedAt
      );
      if (dup) e.email = 'Покупатель с такой почтой уже есть';
    }

    const card = body.card;
    if (card && typeof card === 'object') {
      if (!str(card.number)) e['card.number'] = 'Укажите номер карты';
      else if (str(card.number).length < 4) {
        e['card.number'] = 'Номер карты: минимум 4 символа';
      }
      if (!str(card.issuedAt)) e['card.issuedAt'] = 'Укажите дату выдачи';
      else if (!/^\d{4}-\d{2}-\d{2}$/.test(str(card.issuedAt))) {
        e['card.issuedAt'] = 'Дата в формате ГГГГ-ММ-ДД';
      }
      if (card.points != null) {
        const points = Number(card.points);
        if (!Number.isInteger(points) || points < 0) {
          e['card.points'] = 'Баллы — целое число не меньше нуля';
        }
      }
      if (
        card.tier &&
        !['basic', 'silver', 'gold'].includes(str(card.tier))
      ) {
        e['card.tier'] = 'Уровень: basic, silver или gold';
      }
    }
  }

  return e;
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

const ROLE_LEVEL = { customer: 1, manager: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = [
  'products',
  'categories',
  'manufacturers',
  'materials',
  'customers',
];

function referencesTo(collection, id) {
  if (collection === 'categories') {
    return db.products.filter(
      (p) => p.categoryId === id && !p.deletedAt
    ).length;
  }
  if (collection === 'manufacturers') {
    return db.products.filter(
      (p) => p.manufacturerId === id && !p.deletedAt
    ).length;
  }
  if (collection === 'materials') {
    return db.products.filter(
      (p) => p.materialIds.includes(id) && !p.deletedAt
    ).length;
  }
  return 0;
}

const REFERENCE_NAMES = {
  categories: 'к категории привязано товаров',
  manufacturers: 'к производителю привязано товаров',
  materials: 'материал используется в товарах',
};

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) =>
    Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : [];

  switch (collection) {
    case 'products':
      return {
        name: str(body.name),
        sku: str(body.sku),
        description: str(body.description),
        style: str(body.style),
        price: num(body.price) ?? 0,
        stock: num(body.stock) ?? 0,
        width: num(body.width),
        depth: num(body.depth),
        height: num(body.height),
        weight: num(body.weight),
        color: str(body.color),
        categoryId: num(body.categoryId),
        manufacturerId: num(body.manufacturerId),
        materialIds: ids(body.materialIds),
      };
    case 'categories':
      return { name: str(body.name), description: str(body.description) };
    case 'manufacturers':
      return {
        name: str(body.name),
        country: str(body.country),
        contactEmail: str(body.contactEmail),
      };
    case 'materials':
      return { name: str(body.name), description: str(body.description) };
    case 'customers':
      return {
        fullName: str(body.fullName),
        email: str(body.email),
        phone: str(body.phone),
        address: str(body.address),
        card: normalizeCard(body.card),
      };
    default:
      return { ...body };
  }
}

function normalizeCard(card) {
  if (card == null || typeof card !== 'object') return null;
  const str = (v) => (v == null ? '' : String(v).trim());
  return {
    number: str(card.number),
    issuedAt: str(card.issuedAt),
    tier: str(card.tier) || 'basic',
    points: Number(card.points) || 0,
  };
}

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  if (q.__fail) {
    return fail(
      res,
      Number(q.__fail),
      'Ошибка вызвана намеренно параметром __fail'
    );
  }

  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, {
      message: 'Данные восстановлены в исходное состояние',
    });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const found = db.users.find(
      (u) =>
        u.username === String(body.username || '').trim() && !u.deletedAt
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }

    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({
      sub: found.id,
      role: found.role,
      type: 'access',
      exp: now + ACCESS_TTL,
    });
    const refreshToken = sign({
      sub: found.id,
      type: 'refresh',
      exp: now + REFRESH_TTL,
    });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const username = String(body.username || '').trim();
    const fullName = String(body.fullName || '').trim();
    const email = String(body.email || '').trim();
    const password = String(body.password || '');
    const errors = {};

    if (!/^[a-zA-Z0-9._-]{3,32}$/.test(username)) {
      errors.username = 'Логин: 3–32 символа, латиница, цифры, точка, дефис или подчёркивание';
    } else if (db.users.some((u) => u.username === username)) {
      errors.username = 'Такой логин уже занят';
    }
    if (fullName.length < 3) errors.fullName = 'Укажите имя и фамилию';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errors.email = 'Некорректный адрес почты';
    } else if (db.users.some((u) => u.email.toLowerCase() === email.toLowerCase())) {
      errors.email = 'Пользователь с такой почтой уже зарегистрирован';
    }
    if (password.length < 8) {
      errors.password = 'Пароль: минимум 8 символов';
    } else if (!/\d/.test(password)) {
      errors.password = 'Пароль должен содержать цифру';
    } else if (!/[^A-Za-z0-9]/.test(password)) {
      errors.password = 'Пароль должен содержать специальный символ';
    }

    if (Object.keys(errors).length) {
      return send(res, 422, { message: 'Ошибка валидации', errors });
    }

    const customerId = push('customers', {
      fullName,
      email,
      phone: '',
      address: '',
      card: null,
    });
    const userId = push('users', {
      username,
      passwordHash: hash(password),
      fullName,
      email,
      role: 'customer',
      customerId,
    });
    const found = db.users.find((u) => u.id === userId);

    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({
      sub: found.id,
      role: found.role,
      type: 'access',
      exp: now + ACCESS_TTL,
    });
    const refreshToken = sign({
      sub: found.id,
      type: 'refresh',
      exp: now + REFRESH_TTL,
    });
    db.refreshTokens.add(refreshToken);

    return send(res, 201, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');

    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({
      sub: found.id,
      role: found.role,
      type: 'access',
      exp: now + ACCESS_TTL,
    });
    const refreshToken = sign({
      sub: found.id,
      type: 'refresh',
      exp: now + REFRESH_TTL,
    });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  if (path === '/api/users' && method === 'GET') {
    if (!requireRole(res, user, 'admin')) return;
    const rows = applySort('users', db.users.filter((u) => !u.deletedAt), q.sort);
    const page = paginate(rows, q);
    return send(res, 200, {
      ...page,
      items: page.items.map(expandUser),
    });
  }

  const userMatch = path.match(/^\/api\/users\/(\d+)$/);
  if (userMatch) {
    if (!requireRole(res, user, 'admin')) return;
    const userId = Number(userMatch[1]);
    const row = db.users.find((u) => u.id === userId && !u.deletedAt);
    if (!row) return fail(res, 404, 'Пользователь не найден');

    if (method === 'PATCH' || method === 'PUT') {
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
      const role = String(body.role || '');
      if (!Object.keys(ROLE_LEVEL).includes(role)) {
        return send(res, 422, {
          message: 'Ошибка валидации',
          errors: { role: 'Допустимые роли: customer, manager, admin' },
        });
      }
      if (row.id === user.id && role !== 'admin') {
        return fail(res, 409, 'Нельзя снять с себя роль администратора');
      }
      row.role = role;
      return send(res, 200, expandUser(row));
    }

    if (method === 'DELETE') {
      if (row.id === user.id) {
        return fail(res, 409, 'Нельзя удалить собственную учётную запись');
      }
      const admins = db.users.filter(
        (u) => u.role === 'admin' && !u.deletedAt
      ).length;
      if (row.role === 'admin' && admins <= 1) {
        return fail(res, 409, 'Нельзя удалить последнего администратора');
      }
      row.deletedAt = new Date().toISOString();
      return send(res, 204);
    }
  }

  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);

  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) {
      return fail(res, 404, 'Ресурс не найден');
    }
    if (!requireRole(res, user, 'manager')) return;

    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids)
      ? body.ids.map(Number)
      : [];
    if (!ids.length) {
      return send(res, 422, {
        message: 'Ошибка валидации',
        errors: { ids: 'Передайте непустой список идентификаторов' },
      });
    }

    let deleted = 0;
    for (const row of db[collection]) {
      if (!ids.includes(row.id) || row.deletedAt) continue;
      if (referencesTo(collection, row.id) > 0) continue;
      row.deletedAt = new Date().toISOString();
      deleted += 1;
    }
    return send(res, 200, { deleted });
  }

  const m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);

  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) {
      return fail(res, 404, 'Ресурс не найден');
    }
    const expand = EXPANDERS[collection];

    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = db[collection].find((x) => x.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'GET') {
      let rows = db[collection];
      const withDeleted = q.includeDeleted === 'true' || q.deleted === '1';
      if (!withDeleted) {
        rows = rows.filter((x) => !x.deletedAt);
      }
      rows = applyFilters(collection, rows, q);
      rows = applySort(collection, rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, {
        ...page,
        items: page.items.map(expand),
      });
    }

    if (id !== null && method === 'GET') {
      const withDeleted = q.includeDeleted === 'true' || q.deleted === '1';
      const row = db[collection].find(
        (x) => x.id === id && (withDeleted || !x.deletedAt)
      );
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'manager')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const errors = validate(collection, body);
      if (Object.keys(errors).length) {
        return send(res, 422, { message: 'Ошибка валидации', errors });
      }

      const newId = push(collection, normalize(collection, body));
      const row = db[collection].find((x) => x.id === newId);
      return send(res, 201, expand(row));
    }

    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'manager')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');

      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) {
        return send(res, 422, { message: 'Ошибка валидации', errors });
      }

      Object.assign(row, normalize(collection, merged));
      return send(res, 200, expand(row));
    }

    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'manager')) return;

      const index = db[collection].findIndex((x) => x.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');

      const references = referencesTo(collection, id);
      if (references > 0) {
        return fail(
          res,
          409,
          `Нельзя удалить: ${REFERENCE_NAMES[collection]} — ${references}`
        );
      }

      if (hard) {
        db[collection].splice(index, 1);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

seed();


const DB_URL = env('SUPABASE_DB_URL', '');
const sql = DB_URL
  ? postgres(DB_URL, { ssl: 'require', max: 1, idle_timeout: 15, connect_timeout: 10 })
  : null;
let schemaReady = false;

async function ensureSchema() {
  if (!sql || schemaReady) return;
  await sql`create table if not exists app_state (
    id int primary key,
    data jsonb not null,
    updated_at timestamptz not null default now()
  )`;
  schemaReady = true;
}

async function loadState(exec = sql, lock = false) {
  if (!sql) return;
  const rows = lock
    ? await exec`select data from app_state where id = 1 for update`
    : await exec`select data from app_state where id = 1`;
  if (!rows.length) {
    seed();
    await saveState(exec);
    return;
  }
  const data = rows[0].data;
  data.refreshTokens = new Set(data.refreshTokens || []);
  db = data;
}

async function saveState(exec = sql) {
  if (!sql) return;
  const payload = { ...db, refreshTokens: [...db.refreshTokens] };
  await exec`insert into app_state (id, data, updated_at)
             values (1, ${exec.json(payload)}, now())
             on conflict (id) do update set data = excluded.data, updated_at = now()`;
}

let queue = Promise.resolve();
const serialize = (task) => {
  const run = queue.then(task, task);
  queue = run.then(() => {}, () => {});
  return run;
};

function nodeRequest(request, bodyText) {
  const url = new URL(request.url);
  const shim = {
    method: request.method,
    url: url.pathname + url.search,
    headers: Object.fromEntries(request.headers.entries()),
    on() {
      return shim;
    },
    [Symbol.asyncIterator]() {
      let sent = false;
      return {
        next() {
          if (sent || !bodyText) {
            sent = true;
            return Promise.resolve({ done: true, value: undefined });
          }
          sent = true;
          return Promise.resolve({
            done: false,
            value: Buffer.from(bodyText, 'utf8')
          });
        }
      };
    }
  };

  return shim;
}

function nodeResponse() {
  const state = { status: 200, headers: {}, body: '', sent: false };
  const shim = {
    headersSent: false,
    statusCode: 200,
    setHeader(name, value) {
      state.headers[String(name)] = String(value);
    },
    writeHead(status, extra) {
      state.status = status;
      shim.statusCode = status;
      shim.headersSent = true;
      state.sent = true;
      if (extra) {
        for (const [name, value] of Object.entries(extra)) {
          state.headers[String(name)] = String(value);
        }
      }
    },
    end(chunk) {
      if (chunk) state.body += String(chunk);
    }
  };
  return { shim, state };
}

Deno.serve(async (request) => {
  const url = new URL(request.url);
  const marker = url.pathname.lastIndexOf('/api');
  if (marker > 0) {
    url.pathname = url.pathname.slice(marker);
  }

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': ORIGIN,
        'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400'
      }
    });
  }

  const bodyText =
    request.method === 'GET' || request.method === 'HEAD'
      ? ''
      : await request.text();

  const persist = request.method !== 'GET' && request.method !== 'HEAD';

  const runOnce = async (exec, lock) => {
    await loadState(exec, lock);
    const { shim, state } = nodeResponse();
    const req = nodeRequest(request, bodyText);
    try {
      await handle(req, shim, url);
    } catch (error) {
      if (!state.sent) {
        fail(shim, 500, 'Внутренняя ошибка сервера: ' + String(error && error.message));
      }
    }
    if (persist && state.status < 400) {
      await saveState(exec);
    }
    return state;
  };

  let state;
  try {
    state = await serialize(async () => {
      if (sql) {
        await ensureSchema();
        return persist
          ? await sql.begin((tx) => runOnce(tx, true))
          : await runOnce(sql, false);
      }
      return runOnce(sql, false);
    });
  } catch (error) {
    console.error('state failed: ' + String(error && error.message));
    return new Response(
      JSON.stringify({ message: 'Хранилище недоступно, повторите позже' }),
      {
        status: 503,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': ORIGIN
        }
      }
    );
  }

  const headers = { ...state.headers, 'Access-Control-Allow-Origin': ORIGIN };
  const status = state.status;
  if (status === 204) {
    return new Response(null, { status, headers });
  }

  return new Response(state.body, { status, headers });
});
