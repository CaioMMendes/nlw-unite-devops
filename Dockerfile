#todo É comum ter dois Dockerfiles um para ambiente de desenvolvimento e um para ambiente de produção
#todo No nlw só vai ser abordado o de produção, mas é basicamente a mesma coisa


#Trabalhar baseado na imagem do nodejs
FROM node:20 AS base

# RUN npm i -g pnpm


FROM base AS dependecies

WORKDIR /usr/src/app

# O ./ É o diretório de destino dos dois arquivos copiados
COPY package.json package-lock.json ./

RUN npm install



FROM base AS build


WORKDIR /usr/src/app

# isso faz a cópia de todos os arquivos para a raiz, então é uma boa pratica ignorar o arquivos indesejados no .dockerignore
COPY . .

# Copia dos arquivos da area de dependencies que foi gerado anteriormente, pega a pasta node_modules de lá e coloca na
# pasta node_modules do diretorio atual
COPY --from=dependecies /usr/src/app/node_modules ./node_modules

RUN npm run build
RUN npm prune --prod

#alphine é uma distro do linux que contem somente o necessário então ele é bem menor
FROM node:20-alpine3.19 AS deploy

WORKDIR /usr/src/app

RUN npm i -g prisma 

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/prisma ./prisma

# Não é uma boa pratica passar os envs aqui, é melhor passar no docker-compose
# ENV DATABASE_URL='file:./db.sqlite'
# ENV API_BASE_URL='http://localhost:3333'



RUN npx prisma generate


# Boa pratica passar a porta da aplicação
EXPOSE 3333

CMD [ "npm", "start" ]


#Pra rodar
# docker build -t passin:v1 . -d

# passin seria o nome do aplicativo, tipo node, e o v1 seria o 20 que é a versão
# o . é pra fazer o build baseado no dockerfile baseado na raiz, se não estiver na raiz, passar um -f e 
# navegar até a pasta do arquivo


#para rodar o container 
# docker run -p 5005:3333 passin:v1