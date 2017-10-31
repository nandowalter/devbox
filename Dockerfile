FROM node:8.6.0-alpine
MAINTAINER Fernando Walter Gagni <nandowalter@gmail.com>

ARG username=dev
ARG git_useremail="nandowalter@gmail.com"
ARG git_username="Fernando Walter Gagni"

# Add the patch fix (https://github.com/sass/node-sass/issues/2031)
COPY common/stack-fix.c /lib/

RUN apk update && apk upgrade && \
    apk add --no-cache bash zsh git openssh curl vim sudo shadow ca-certificates openssl python && \
	update-ca-certificates

RUN adduser -g '' -D -s /bin/bash $username

RUN echo "$username ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$username && \
    chmod 0440 /etc/sudoers.d/$username

RUN git clone --depth=1 https://github.com/Bash-it/bash-it.git /home/$username/.bash_it && \
	/home/$username/.bash_it/install.sh --silent && \
	mv ~/.bashrc /home/$username/

RUN sed -i -e "s/export BASH_IT_THEME='bobby'/export BASH_IT_THEME='nwinkler'/g" /home/$username/.bashrc

RUN export ZSH="/home/$username/.oh-my-zsh"; sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true && \
	mv ~/.zshrc /home/$username/ && \
	chown -R $username:$username /home/$username/.zshrc && \
	git clone https://github.com/powerline/fonts.git --depth=1 && \
	cd fonts && \
	./install.sh && \
	cd .. && \
	rm -rf fonts && \
	mkdir -p /home/$username/.local/share/fonts && \
	mv ~/.local/share/fonts/* /home/$username/.local/share/fonts/ && \
	mkdir -p /home/$username/.oh-my-zsh/custom/themes && \
	git clone https://github.com/caiogondim/bullet-train.zsh.git --depth=1 && \
	mv ./bullet-train.zsh/bullet-train.zsh-theme /home/$username/.oh-my-zsh/custom/themes/ && \
	sed -i -e "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"bullet-train\"/g" /home/$username/.zshrc && \
	chown -R $username:$username /home/$username/.local && \
	echo "BULLETTRAIN_PROMPT_ORDER=( \
    time \
    status \
    custom \
    context \
    dir \
    perl \
    ruby \
    virtualenv \
    aws \
    go \
    elixir \
    git \
    hg \
    cmd_exec_time \
    )" >> /home/$username/.zshrc

RUN	echo -e "if [ ! -n \"\${BULLETTRAIN_GIT_AHEAD+1}\" ]; then \n \
			ZSH_THEME_GIT_PROMPT_AHEAD=\" ┬\" \n \
		else \n \
			ZSH_THEME_GIT_PROMPT_AHEAD=\$BULLETTRAIN_GIT_AHEAD \n \
		fi \n \
		if [ ! -n \"\${BULLETTRAIN_GIT_BEHIND+1}\" ]; then \n \
			ZSH_THEME_GIT_PROMPT_BEHIND=\" ┴\" \n \
		else \n \
			ZSH_THEME_GIT_PROMPT_BEHIND=\$BULLETTRAIN_GIT_BEHIND \n \
		fi \n \
		if [ ! -n \"\${BULLETTRAIN_GIT_DIVERGED+1}\" ]; then \n \
			ZSH_THEME_GIT_PROMPT_DIVERGED=\" ├\" \n \
		else \n \
			ZSH_THEME_GIT_PROMPT_DIVERGED=\$BULLETTRAIN_GIT_PROMPT_DIVERGED \n \
		fi" >> /home/$username/.zshrc

RUN echo -e "alias wds='./node_modules/.bin/webpack-dev-server --config config/webpack.config.dev.js --progress --color' \n" >> /home/$username/.zshrc

RUN apk add tzdata && \
	cp /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
	echo "Europe/Rome" >  /etc/timezone && \
	apk del tzdata
	
RUN npm install -g gulp bower

RUN git config --system user.email "$git_useremail" && \
	git config --system user.name "$git_username" && \
	git config --system core.autocrlf input

# Prepare the libraries packages (https://github.com/sass/node-sass/issues/2031)
RUN set -ex \
    && apk add --no-cache  --virtual .build-deps build-base \
    && gcc  -shared -fPIC /lib/stack-fix.c -o /lib/stack-fix.so \
    && apk del .build-deps

# export the environment variable of LD_PRELOAD (https://github.com/sass/node-sass/issues/2031)
ENV LD_PRELOAD /lib/stack-fix.so

USER $username
WORKDIR /home/$username

# port 9000 --> 9005 for development web server
# port 35729, 35730 for connect livereload connection	
EXPOSE 9000 9001 9002 9003 9004 9005 35729 35730