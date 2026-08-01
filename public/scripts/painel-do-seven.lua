-- [[ PAINEL DO SEVEN 1.0.1]] --
if not game:IsLoaded() then game.Loaded:Wait() end

local NOME_PAINEL = "Painel_Sistema_Reset_V17_Master"
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Suporte seguro para injeção via CoreGui ou PlayerGui
local SuporteGui = nil
local sucessoCore, _ = pcall(function() SuporteGui = game:GetService("CoreGui") end)
if not sucessoCore or not SuporteGui then
    SuporteGui = player:WaitForChild("PlayerGui", 15)
end

-- Limpeza absoluta de execuções anteriores para evitar duplicação de conexões
if SuporteGui and SuporteGui:FindFirstChild(NOME_PAINEL) then 
    pcall(function() SuporteGui[NOME_PAINEL]:Destroy() end)
end

if _G.LimparConexoesGlobais then
    pcall(_G.LimparConexoesGlobais)
end

_G.VersaoAtual = (_G.VersaoAtual or 0) + 1
local ID_EXECUCAO = _G.VersaoAtual

local conexoesParaLimpar = {}
_G.LimparConexoesGlobais = function()
    for _, conexao in ipairs(conexoesParaLimpar) do
        if conexao and conexao.Connected then
            pcall(function() conexao:Disconnect() end)
        end
    end
    table.clear(conexoesParaLimpar)
end

-- Variável global interna para referenciar o frame principal do menu
local mainFrameRef = nil

-- Declarações antecipadas (permitem que o botão flutuante reconstrua todo o sistema)
local InicializarPainel
local ConstruirBotaoFlutuante
local ExecutarHardReset
local HardResetEmAndamento = false

-- Dimensões oficiais do painel (usadas na animação de abertura/fechamento)
local PAINEL_LARGURA, PAINEL_ALTURA = 740, 520

local menuAnimando = false
local function AlternarVisibilidadeMenu()
    if not mainFrameRef or menuAnimando then return end
    local frame = mainFrameRef
    local abrindo = not frame.Visible

    menuAnimando = true
    if abrindo then
        frame.Visible = true
        frame.Size = UDim2.new(0, math.floor(PAINEL_LARGURA * 0.86), 0, math.floor(PAINEL_ALTURA * 0.86))
        frame.BackgroundTransparency = 1
        local abrir = TweenService:Create(
            frame,
            TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, PAINEL_LARGURA, 0, PAINEL_ALTURA) }
        )
        TweenService:Create(frame, TweenInfo.new(0.22), { BackgroundTransparency = 0.06 }):Play()
        abrir:Play()
        abrir.Completed:Wait()
    else
        local fechar = TweenService:Create(
            frame,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.new(0, math.floor(PAINEL_LARGURA * 0.88), 0, math.floor(PAINEL_ALTURA * 0.88)), BackgroundTransparency = 1 }
        )
        fechar:Play()
        fechar.Completed:Wait()
        frame.Visible = false
        frame.Size = UDim2.new(0, PAINEL_LARGURA, 0, PAINEL_ALTURA)
        frame.BackgroundTransparency = 0.06
    end
    menuAnimando = false
end

-- [[ INTERFACE DO BOTÃO FLUTUANTE DE ATIVAÇÃO ]] --
-- Clique simples: abre/fecha o painel.
-- Clique duplo (dois toques em até 0.4s): HARD RESET + reinicialização total do código.

local ScreenGuiMaster, BotaoReset

ConstruirBotaoFlutuante = function()
    -- Remove qualquer instância anterior do botão flutuante
    pcall(function()
        for _, gui in ipairs(SuporteGui:GetChildren()) do
            if gui.Name == NOME_PAINEL then gui:Destroy() end
        end
    end)

    ScreenGuiMaster = Instance.new("ScreenGui")
    ScreenGuiMaster.Name = NOME_PAINEL
    ScreenGuiMaster.ResetOnSpawn = false
    ScreenGuiMaster.IgnoreGuiInset = true
    ScreenGuiMaster.DisplayOrder = 2147483647
    ScreenGuiMaster.Parent = SuporteGui

    BotaoReset = Instance.new("TextButton")
    BotaoReset.Name = "GatilhoFlutuante"
    BotaoReset.Size = UDim2.new(0, 48, 0, 48)
    BotaoReset.Position = UDim2.new(0.5, -24, 0.85, 0)
    BotaoReset.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
    BotaoReset.BackgroundTransparency = 0.15
    BotaoReset.AutoButtonColor = false
    BotaoReset.Text = "\u{26A1}"
    BotaoReset.Font = Enum.Font.GothamBold
    BotaoReset.TextColor3 = Color3.fromRGB(0, 255, 255)
    BotaoReset.TextSize = 22
    BotaoReset.ZIndex = 5
    BotaoReset.Parent = ScreenGuiMaster
    Instance.new("UICorner", BotaoReset).CornerRadius = UDim.new(1, 0)

    -- Gradiente interno para dar profundidade
    local GradienteBotao = Instance.new("UIGradient", BotaoReset)
    GradienteBotao.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 30, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 12)),
    })
    GradienteBotao.Rotation = 90

    local ResetStroke = Instance.new("UIStroke", BotaoReset)
    ResetStroke.Color = Color3.fromRGB(0, 255, 255)
    ResetStroke.Thickness = 2
    ResetStroke.Transparency = 0.1

    -- Halo pulsante ao redor do botão (filho, portanto acompanha o arraste)
    local Halo = Instance.new("Frame")
    Halo.Name = "Halo"
    Halo.AnchorPoint = Vector2.new(0.5, 0.5)
    Halo.Position = UDim2.new(0.5, 0, 0.5, 0)
    Halo.Size = UDim2.new(1, 8, 1, 8)
    Halo.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    Halo.BackgroundTransparency = 0.82
    Halo.BorderSizePixel = 0
    Halo.ZIndex = 1
    Halo.Parent = BotaoReset
    Instance.new("UICorner", Halo).CornerRadius = UDim.new(1, 0)

    -- Etiqueta de status (aparece durante o hard reset)
    local Etiqueta = Instance.new("TextLabel")
    Etiqueta.Name = "Etiqueta"
    Etiqueta.AnchorPoint = Vector2.new(0.5, 1)
    Etiqueta.Position = UDim2.new(0.5, 0, 0, -6)
    Etiqueta.Size = UDim2.new(0, 150, 0, 20)
    Etiqueta.BackgroundColor3 = Color3.fromRGB(9, 11, 16)
    Etiqueta.BackgroundTransparency = 0.1
    Etiqueta.Text = ""
    Etiqueta.TextColor3 = Color3.fromRGB(255, 70, 90)
    Etiqueta.Font = Enum.Font.GothamBold
    Etiqueta.TextSize = 10
    Etiqueta.Visible = false
    Etiqueta.ZIndex = 6
    Etiqueta.Parent = BotaoReset
    Instance.new("UICorner", Etiqueta).CornerRadius = UDim.new(0, 6)
    local EtiquetaStroke = Instance.new("UIStroke", Etiqueta)
    EtiquetaStroke.Color = Color3.fromRGB(255, 70, 90)
    EtiquetaStroke.Transparency = 0.35

    -- Pulso contínuo do halo
    task.spawn(function()
        local versaoLocal = _G.VersaoAtual
        while versaoLocal == _G.VersaoAtual and Halo.Parent do
            pcall(function()
                TweenService:Create(Halo, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 18, 1, 18), BackgroundTransparency = 0.95
                }):Play()
            end)
            task.wait(0.95)
            pcall(function()
                TweenService:Create(Halo, TweenInfo.new(0.9, Enum.EasingStyle.Sine), {
                    Size = UDim2.new(1, 6, 1, 6), BackgroundTransparency = 0.8
                }):Play()
            end)
            task.wait(0.95)
        end
    end)

    -- [[ ARRASTE COM DETECÇÃO DE CLIQUE REAL ]] --
    -- Um movimento acima de 6px é considerado arraste e cancela o clique,
    -- evitando que reposicionar o botão abra o painel por acidente.
    local dragAtivo, dragStart, startPos = false, nil, nil
    local houveArraste = false

    table.insert(conexoesParaLimpar, BotaoReset.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragAtivo = true
            houveArraste = false
            dragStart = input.Position
            startPos = BotaoReset.Position
            TweenService:Create(BotaoReset, TweenInfo.new(0.1), { Size = UDim2.new(0, 43, 0, 43) }):Play()
        end
    end))

    table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(input)
        if not dragAtivo then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 6 or math.abs(delta.Y) > 6 then houveArraste = true end
            BotaoReset.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragAtivo then
                TweenService:Create(BotaoReset, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 48, 0, 48)
                }):Play()
            end
            dragAtivo = false
        end
    end))

    -- [[ CLIQUE SIMPLES x CLIQUE DUPLO ]] --
    local INTERVALO_DUPLO = 0.4
    local ultimoClique = 0
    local cliquePendente = nil

    table.insert(conexoesParaLimpar, BotaoReset.MouseButton1Click:Connect(function()
        -- Arrastar nunca deve contar como clique
        if houveArraste then houveArraste = false return end
        if HardResetEmAndamento then return end

        local agora = os.clock()
        if agora - ultimoClique <= INTERVALO_DUPLO then
            -- Segundo toque dentro da janela: cancela a abertura e dispara o hard reset
            ultimoClique = 0
            if cliquePendente then
                pcall(function() task.cancel(cliquePendente) end)
                cliquePendente = nil
            end
            task.spawn(ExecutarHardReset)
        else
            ultimoClique = agora
            -- Aguarda a janela do clique duplo antes de alternar o painel
            cliquePendente = task.delay(INTERVALO_DUPLO, function()
                cliquePendente = nil
                if HardResetEmAndamento then return end
                AlternarVisibilidadeMenu()
            end)
        end
    end))

    return BotaoReset, ResetStroke, Etiqueta, Halo
end

-- [[ HARD RESET + REINICIALIZAÇÃO TOTAL DO CÓDIGO ]] --
ExecutarHardReset = function()
    if HardResetEmAndamento then return end
    HardResetEmAndamento = true

    local botao = BotaoReset
    local etiqueta = botao and botao:FindFirstChild("Etiqueta")
    local stroke = botao and botao:FindFirstChildOfClass("UIStroke")

    -- Feedback visual imediato
    pcall(function()
        botao.Text = "\u{27F3}"
        botao.TextColor3 = Color3.fromRGB(255, 70, 90)
        if stroke then stroke.Color = Color3.fromRGB(255, 70, 90) end
        if etiqueta then
            etiqueta.Visible = true
            etiqueta.Text = "HARD RESET EM ANDAMENTO..."
        end
        local halo = botao:FindFirstChild("Halo")
        if halo then halo.BackgroundColor3 = Color3.fromRGB(255, 70, 90) end
    end)

    -- ETAPA 1: invalida a versão atual, encerrando todos os laços em execução
    _G.VersaoAtual = _G.VersaoAtual + 1

    -- ETAPA 2: desconecta todas as conexões registradas
    pcall(_G.LimparConexoesGlobais)

    -- ETAPA 3: restaura o personagem para o estado limpo
    pcall(function()
        local char = player.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition")
                   or obj:IsA("AlignPosition") or obj:IsA("AlignOrientation") or obj:IsA("LinearVelocity")
                   or obj:IsA("AngularVelocity") then
                    obj:Destroy()
                end
                if obj:IsA("BasePart") then
                    obj.CanCollide = true
                    obj.LocalTransparencyModifier = 0
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.PlatformStand = false
                hum.AutoRotate = true
                for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                    pcall(function() track:Stop(0) end)
                end
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
    end)

    -- ETAPA 4: restaura câmera e sensibilidade
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
    end)

    -- ETAPA 5: remove plataformas/rastros deixados no mundo
    pcall(function()
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and (obj.Name == "PlataformaAgua" or obj.Name == "PlataformaNeon") then
                obj:Destroy()
            end
        end
    end)

    -- ETAPA 6: destrói todas as interfaces geradas pelo painel
    pcall(function()
        local alvos = { "PainelNeonV17_Main", NOME_PAINEL }
        for _, nome in ipairs(alvos) do
            for _, gui in ipairs(SuporteGui:GetChildren()) do
                if gui.Name == nome then gui:Destroy() end
            end
        end
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in ipairs(pg:GetChildren()) do
                if gui.Name == "PainelNeonV17_Main" or gui.Name == NOME_PAINEL then gui:Destroy() end
            end
        end
    end)
    mainFrameRef = nil
    menuAnimando = false

    -- ETAPA 7: reset físico do avatar (quebra as juntas para forçar respawn limpo)
    pcall(function()
        if player.Character then player.Character:BreakJoints() end
    end)

    -- ETAPA 8: janela de segurança para que TODOS os laços antigos encerrem
    -- (alguns usam task.wait de até 1s antes de reavaliar a versão)
    task.wait(1.25)

    -- ETAPA 9: revalida a versão para a nova execução e reconstrói o sistema inteiro
    ID_EXECUCAO = _G.VersaoAtual
    ConstruirBotaoFlutuante()
    task.spawn(InicializarPainel)

    HardResetEmAndamento = false
end

ConstruirBotaoFlutuante()

-- [[ NÚCLEO DO PAINEL PRINCIPAL ]] --
function InicializarPainel()
    local mouse = player:GetMouse()
    local camera = workspace.CurrentCamera
    local PlayerGui = player:WaitForChild("PlayerGui", 15)
    if not PlayerGui then return end
    
    if PlayerGui:FindFirstChild("PainelNeonV17_Main") then pcall(function() PlayerGui["PainelNeonV17_Main"]:Destroy() end) end

    -- ESTADOS OPERACIONAIS
    local clickTPAtivado = false 
    local reAtivado = false
    local flyModoAtivado = false 
    local dashModoAtivado = false 
    local noclipModoPermissao = false
    local waterActive = false

    local VOANDO = false
    local emMovimento = false
    local isNoclip = false
    local isEmotingGlobally = false -- ADICIONE ESTA LINHA AQUI
    local segurandoDash = false
    local targetSpeed = 16
    local ID_UltimoJogadorTeleportado = nil
    local isInvisible = false

    local configVelocidade = { Fly = 20, Dash = 500 }

    local ID_CORRIDA = "rbxassetid://85232146719894" 
    local ID_PARADO = "rbxassetid://133226513780673"
    local ID_VERTICAL = "rbxassetid://133226513780673" -- NOVO ID INSERIDO AQUI
    local TrackCorrida, TrackParado, TrackVertical
    local BV, BG

    local plataformaAgua = nil
    local noclipConnection = nil
    local syncConnectionGhost = nil

    local WATER_STEP_SOUND = "rbxassetid://131015690"
    local SOUND_EFEITO_ID = "rbxassetid://142070127"
    local originalSound, originalPitch = nil, nil

    local FORCA_PULO_EXTRA = 80
    local podePularDuplo = false
    local jaPuloDuplo = false

    local function ObterComponentes()
        local char = player.Character
        if not char then return nil, nil, nil end
        return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    end

    local function GerarRastro()
        local _, _, root = ObterComponentes()
        if not root or ID_EXECUCAO ~= _G.VersaoAtual then return end
        local p = Instance.new("Part")
        p.Size = Vector3.new(1.5, 1.5, 1.5)
        p.Transparency = 0.5
        p.Color = Color3.fromRGB(0, 255, 255)
        p.Material = Enum.Material.Neon
        p.CanCollide = false; p.Anchored = true
        p.CFrame = root.CFrame * CFrame.new(0, -1, 0)
        p.Parent = workspace
        Instance.new("SpecialMesh", p).MeshType = Enum.MeshType.Sphere
        TweenService:Create(p, TweenInfo.new(0.4), {Size = Vector3.new(4, 4, 4), Transparency = 1}):Play()
        Debris:AddItem(p, 0.4)
    end

    local function TocarSomEfeito()
        local _, _, root = ObterComponentes()
        if not root then return end
        local boom = Instance.new("Part", workspace)
        boom.Shape, boom.Material, boom.Transparency = Enum.PartType.Ball, Enum.Material.ForceField, 0.4
        boom.CanCollide, boom.Anchored, boom.CFrame, boom.Size = false, true, root.CFrame, Vector3.new(2, 2, 2)
        local som = Instance.new("Sound", boom)
        som.SoundId, som.Volume = SOUND_EFEITO_ID, 0.35
        som:Play()
        TweenService:Create(boom, TweenInfo.new(0.5), {Size = Vector3.new(25, 25, 25), Transparency = 1}):Play()
        Debris:AddItem(boom, 0.6)
    end

    local function CarregarAnimacoes(humanoid)
        if not humanoid then return end
        pcall(function()
            -- O Roblox recomenda usar o 'Animator' para evitar falhas de carregamento
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end

            local animCorrida = Instance.new("Animation")
            animCorrida.AnimationId = ID_CORRIDA
            local animParado = Instance.new("Animation")
            animParado.AnimationId = ID_PARADO
            local animVertical = Instance.new("Animation")
            animVertical.AnimationId = ID_VERTICAL

            -- Carregando as tracks de forma segura pelo Animator
            TrackCorrida = animator:LoadAnimation(animCorrida)
            TrackParado = animator:LoadAnimation(animParado)
            TrackVertical = animator:LoadAnimation(animVertical)

            -- Definindo as prioridades (Action força a animação vertical a se destacar)
            TrackCorrida.Priority = Enum.AnimationPriority.Movement
            TrackParado.Priority = Enum.AnimationPriority.Movement
            TrackVertical.Priority = Enum.AnimationPriority.Action
        end)
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PainelNeonV17_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 2147483647 -- Força o painel a ficar na camada mais alta
    screenGui.Parent = SuporteGui -- Envia para o CoreGui em vez do PlayerGui

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0, 360, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -180, 0.5, -240)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
    mainFrame.BackgroundTransparency = 0.25 
    mainFrame.Visible = true 
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    mainFrameRef = mainFrame 

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(0, 255, 255)
    mainStroke.Thickness = 1.5

    local topBar = Instance.new("Frame", mainFrame)
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    topBar.BackgroundTransparency = 0.15
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
    local topStroke = Instance.new("UIStroke", topBar)
    topStroke.Color = Color3.fromRGB(0, 255, 255)

    local raioAnimado = Instance.new("TextLabel", topBar)
    raioAnimado.Size = UDim2.new(0, 50, 1, 0)
    raioAnimado.Position = UDim2.new(0, 12, 0, 0)
    raioAnimado.Text = "⚡"
    raioAnimado.TextColor3 = Color3.fromRGB(0, 255, 255)
    raioAnimado.BackgroundTransparency = 1
    raioAnimado.Font = Enum.Font.GothamBold
    raioAnimado.TextSize = 20
    raioAnimado.TextXAlignment = Enum.TextXAlignment.Left

    task.spawn(function()
        while ID_EXECUCAO == _G.VersaoAtual and task.wait(0.5) do
            pcall(function()
                local corAlvo = raioAnimado.TextColor3 == Color3.fromRGB(0, 255, 255) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 255, 255)
                local tamAlvo = raioAnimado.TextSize == 20 and 24 or 20
                TweenService:Create(raioAnimado, TweenInfo.new(0.4), {TextColor3 = corAlvo, TextSize = tamAlvo}):Play()
            end)
        end
    end)

    local titleLabel = Instance.new("TextLabel", topBar)
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, 50, 0, 0)
    titleLabel.Text = "⚡ PAINEL DO SEVEN [P]"
    titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamMedium 
    titleLabel.TextSize = 8
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local function criarBotaoMenu(texto, posY, corNeon)
        local btn = Instance.new("TextButton", mainFrame)
        btn.Size = UDim2.new(0, 75, 0, 45)
        btn.Position = UDim2.new(1, 12, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
        btn.Text = texto
        btn.TextColor3 = corNeon
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 8
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = corNeon
        stroke.Thickness = 1.5
        return btn
    end

    local btnCtrlTP = criarBotaoMenu("CTRL TP", 45, Color3.fromRGB(0, 255, 255))
    local btnRE = criarBotaoMenu("RE", 100, Color3.fromRGB(0, 255, 255))
    local btnFLY = criarBotaoMenu("FLY [V]", 155, Color3.fromRGB(0, 255, 255))
    local btnNOCLIP = criarBotaoMenu("NOCLIP [E]", 210, Color3.fromRGB(0, 255, 255))
    local btnDASH = criarBotaoMenu("DASH [Q]", 265, Color3.fromRGB(0, 255, 255))
    local btnWATER = criarBotaoMenu("ÁGUA [F]", 320, Color3.fromRGB(0, 255, 255))
    
    local btnREJOIN = criarBotaoMenu("REJOIN", 45, Color3.fromRGB(255, 0, 50))
    btnREJOIN.Position = UDim2.new(0, -88, 0, 45)

    local function criarSlider(nome, posY, min, max, padrao, tipoChave, corFill)
        local sliderFrame = Instance.new("Frame", mainFrame)
        sliderFrame.Size = UDim2.new(0, 135, 0, 42)
        sliderFrame.Position = UDim2.new(1, 95, 0, posY)
        sliderFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 8)
        local sfStroke = Instance.new("UIStroke", sliderFrame)
        sfStroke.Color = corFill
        sfStroke.Thickness = 1

        local sliderBar = Instance.new("Frame", sliderFrame)
        sliderBar.Size = UDim2.new(0.8, 0, 0, 4)
        sliderBar.Position = UDim2.new(0.1, 0, 0.7, 0)
        sliderBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

        local sliderFill = Instance.new("Frame", sliderBar)
        sliderFill.BackgroundColor3 = corFill
        
        local sliderBtn = Instance.new("TextButton", sliderBar)
        sliderBtn.Size = UDim2.new(0, 12, 0, 12)
        sliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sliderBtn.Text = ""
        Instance.new("UICorner", sliderBtn)

        local label = Instance.new("TextLabel", sliderFrame)
        label.Size = UDim2.new(1, 0, 0.5, 0)
        label.Position = UDim2.new(0, 0, 0.1, 0)
        label.TextColor3 = corFill
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 9

        local function atualizar(percent)
            percent = math.clamp(percent, 0, 1)
            local valor = math.floor(min + (percent * (max - min)))
            label.Text = nome .. ": " .. valor
            configVelocidade[tipoChave] = valor
            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
            sliderBtn.Position = UDim2.new(percent, -6, 0.5, -6)
        end
        
        atualizar((padrao - min) / (max - min))
        local arrastando = false
        sliderBtn.MouseButton1Down:Connect(function() arrastando = true end)
        
        table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.MouseButton1 then arrastando = false end 
        end))
        
        table.insert(conexoesParaLimpar, RunService.RenderStepped:Connect(function()
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if arrastando then
                local percent = (mouse.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X
                atualizar(percent)
            end
        end))
    end

    criarSlider("NEON VEL", 155, 20, 400, 100, "Fly", Color3.fromRGB(0, 255, 255))
    criarSlider("DASH VEL", 265, 10, 500, 150, "Dash", Color3.fromRGB(255, 0, 255))

    local searchBar = Instance.new("TextBox", mainFrame)
    searchBar.Size = UDim2.new(0, 336, 0, 35)
    searchBar.Position = UDim2.new(0, 12, 0, 52)
    searchBar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    searchBar.PlaceholderText = "Pesquisar nome ou @usuário..."
    searchBar.Text = ""
    searchBar.TextColor3 = Color3.fromRGB(0, 255, 255)
    searchBar.PlaceholderColor3 = Color3.fromRGB(50, 75, 75)
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextSize = 8
    Instance.new("UICorner", searchBar).CornerRadius = UDim.new(0, 8)
    local sbStroke = Instance.new("UIStroke", searchBar)
    sbStroke.Color = Color3.fromRGB(0, 255, 255)

    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -24, 1, -165)
    scroll.Position = UDim2.new(0, 12, 0, 98)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
    local listLayout = Instance.new("UIListLayout", scroll)
    listLayout.Padding = UDim.new(0, 6)

    local refreshBtn = Instance.new("TextButton", mainFrame)
    refreshBtn.Size = UDim2.new(0, 336, 0, 38)
    refreshBtn.Position = UDim2.new(0, 12, 1, -48)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    refreshBtn.Text = "ATUALIZAR LISTA JOGADORES"
    refreshBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
    refreshBtn.Font = Enum.Font.GothamMedium
    refreshBtn.TextSize = 8
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)
    local rbStroke = Instance.new("UIStroke", refreshBtn)
    rbStroke.Color = Color3.fromRGB(0, 255, 255)

    local function updateList()
        for _, item in ipairs(scroll:GetChildren()) do 
            if item:IsA("Frame") then item:Destroy() end 
        end
        local filtro = searchBar.Text:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local matchesFilter = (filtro == "") or 
                                      string.find(p.DisplayName:lower(), filtro, 1, true) or 
                                      string.find(p.Name:lower(), filtro, 1, true)
                if matchesFilter then
                    local pFrame = Instance.new("Frame", scroll)
                    pFrame.Size = UDim2.new(1, -5, 0, 42)
                    pFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
                    Instance.new("UICorner", pFrame).CornerRadius = UDim.new(0, 6)
                    local pfStroke = Instance.new("UIStroke", pFrame)
                    pfStroke.Color = Color3.fromRGB(0, 255, 255)
                    pfStroke.Thickness = 0.7

                    local label = Instance.new("TextLabel", pFrame)
                    label.Size = UDim2.new(0.65, 0, 1, 0)
                    label.Position = UDim2.new(0, 8, 0, 0)
                    label.Text = p.DisplayName .. "\n(@" .. p.Name .. ")"
                    label.TextColor3 = Color3.fromRGB(0, 255, 255)
                    label.Font = Enum.Font.Gotham; label.TextSize = 9.5; label.TextXAlignment = Enum.TextXAlignment.Left
                    label.BackgroundTransparency = 1

                    local tp = Instance.new("TextButton", pFrame)
                    tp.Size = UDim2.new(0, 68, 0, 24)
                    tp.Position = UDim2.new(1, -74, 0, 8)
                    tp.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
                    tp.Font = Enum.Font.GothamBold; tp.TextSize = 8.5; Instance.new("UICorner", tp)
                    local tpStroke = Instance.new("UIStroke", tp)
                    tpStroke.Thickness = 1

                    if ID_UltimoJogadorTeleportado == p.UserId then
                        tp.TextColor3 = Color3.fromRGB(0, 0, 0)
                        tp.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                        tp.Text = "CONECTADO"
                        tpStroke.Color = Color3.fromRGB(46, 204, 113)
                    else
                        tp.TextColor3 = Color3.fromRGB(255, 0, 255)
                        tp.Text = "TELEPORT"
                        tpStroke.Color = Color3.fromRGB(255, 0, 255)
                    end

                    tp.MouseButton1Click:Connect(function()
                        local _, _, root = ObterComponentes()
                        if root and p.Character then
                            local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                            if targetHrp then
                                root.CFrame = targetHrp.CFrame * CFrame.new(0, 3, 0)
                                ID_UltimoJogadorTeleportado = p.UserId
                                updateList()
                            else
                                tp.Text = "LONGE DEMAIS"
                                tp.TextColor3 = Color3.fromRGB(255, 50, 50)
                                tpStroke.Color = Color3.fromRGB(255, 50, 50)
                                task.delay(1.5, function()
                                    if tp and tp.Parent then
                                        tp.Text = "TELEPORT"
                                        tp.TextColor3 = Color3.fromRGB(255, 0, 255)
                                        tpStroke.Color = Color3.fromRGB(255, 0, 255)
                                    end
                                end)
                            end
                        end
                    end)
                end
            end
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end

    btnREJOIN.MouseButton1Click:Connect(function()
        pcall(function()
            if #Players:GetPlayers() <= 1 then TeleportService:Teleport(game.PlaceId, player)
            else TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end
        end)
    end)

    btnCtrlTP.MouseButton1Click:Connect(function()
        if isNoclip then return end
        clickTPAtivado = not clickTPAtivado
        btnCtrlTP.BackgroundColor3 = clickTPAtivado and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnCtrlTP.TextColor3 = clickTPAtivado and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
    end)

    btnRE.MouseButton1Click:Connect(function()
        if isNoclip then return end
        reAtivado = not reAtivado
        btnRE.BackgroundColor3 = reAtivado and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnRE.TextColor3 = reAtivado and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 0, 255)
    end)

    local function DesativarFisicaFly()
        VOANDO = false
        if BV then pcall(function() BV:Destroy() end) BV = nil end
        if BG then pcall(function() BG:Destroy() end) BG = nil end
        if TrackCorrida then TrackCorrida:Stop(0.1) end
        if TrackParado then TrackParado:Stop(0.1) end
        if TrackVertical then TrackVertical:Stop(0.1) end -- NOVO: Para a animação ao desligar o Fly
        emMovimento = false
        local _, hum = ObterComponentes()
        if hum then hum.PlatformStand = false end
    end

    btnFLY.MouseButton1Click:Connect(function()
        flyModoAtivado = not flyModoAtivado
        btnFLY.BackgroundColor3 = flyModoAtivado and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnFLY.TextColor3 = flyModoAtivado and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        if not flyModoAtivado and VOANDO then DesativarFisicaFly() end
    end)

    btnNOCLIP.MouseButton1Click:Connect(function()
        noclipModoPermissao = not noclipModoPermissao
        btnNOCLIP.BackgroundColor3 = noclipModoPermissao and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnNOCLIP.TextColor3 = noclipModoPermissao and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 0, 255)
    end)

    btnDASH.MouseButton1Click:Connect(function()
        dashModoAtivado = not dashModoAtivado
        btnDASH.BackgroundColor3 = dashModoAtivado and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnDASH.TextColor3 = dashModoAtivado and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
    end)

    btnWATER.MouseButton1Click:Connect(function()
        waterActive = not waterActive
        btnWATER.BackgroundColor3 = waterActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
        btnWATER.TextColor3 = waterActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
    end)

    local function AlternarNoclip()
        isNoclip = not isNoclip
        
        if isNoclip then
            if noclipConnection then noclipConnection:Disconnect() end
            
            -- Stepped é ideal para física e colisão no Roblox
            noclipConnection = RunService.Stepped:Connect(function()
                if ID_EXECUCAO ~= _G.VersaoAtual then return end
                
                -- Pega o personagem atual dentro do loop (Evita o bug se o jogador morrer com noclip ligado)
                local charAtual = player.Character
                if charAtual then
                    for _, v in ipairs(charAtual:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        else
            -- Desliga o loop de colisão
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            
            -- O SEGREDO DA CORREÇÃO: Forçar a colisão a voltar imediatamente
            local charAtual = player.Character
            if charAtual then
                for _, v in ipairs(charAtual:GetDescendants()) do
                    if v:IsA("BasePart") then
                        -- Restauramos as partes essenciais para que o personagem volte a ter física normal
                        if v.Name == "HumanoidRootPart" or v.Name == "Head" or v.Name == "Torso" or v.Name == "UpperTorso" or v.Name == "LowerTorso" then
                            v.CanCollide = true
                        end
                    end
                end
            end
        end
    end

    table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gpe)
        if ID_EXECUCAO ~= _G.VersaoAtual or gpe then return end
        
        if input.KeyCode == Enum.KeyCode.P then AlternarVisibilidadeMenu() end
        if noclipModoPermissao and input.KeyCode == Enum.KeyCode.E then AlternarNoclip() end
        
        if input.KeyCode == Enum.KeyCode.F then
            waterActive = not waterActive
            btnWATER.BackgroundColor3 = waterActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnWATER.TextColor3 = waterActive and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        end
        
        if not isInvisible then
            local char, hum, root = ObterComponentes()
            if not char or not root or not hum then return end

            if reAtivado and input.KeyCode == Enum.KeyCode.R then
                local pos = root.CFrame
                char:BreakJoints()
                local novoChar = player.CharacterAdded:Wait()
                task.wait(0.2); novoChar:PivotTo(pos)
            end
            
            if dashModoAtivado and input.KeyCode == Enum.KeyCode.Q then 
                segurandoDash = true 
                if hum.MoveDirection.Magnitude > 0 then 
                    TocarSomEfeito() 
                end
            end
            
            if flyModoAtivado and input.KeyCode == Enum.KeyCode.V then
                VOANDO = not VOANDO
                if not VOANDO then
                    DesativarFisicaFly()
                else
                    hum.PlatformStand = true
                    TocarSomEfeito()
                    BV = Instance.new("BodyVelocity", root)
                    BV.MaxForce = Vector3.new(1, 1, 1) * math.huge
                    BG = Instance.new("BodyGyro", root)
                    BG.MaxTorque = Vector3.new(1, 1, 1) * math.huge
                    BG.P = 6000
                    if TrackParado then TrackParado:Play(0.1) end
                end
            end
            
            if clickTPAtivado and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                char:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
            end
        end
    end))

    table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Q then segurandoDash = false end
    end))

    table.insert(conexoesParaLimpar, RunService.RenderStepped:Connect(function()
        if ID_EXECUCAO ~= _G.VersaoAtual then return end
        local _, hum, root = ObterComponentes()
        if not root or not hum or isNoclip then return end

        if segurandoDash and dashModoAtivado then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                root.CFrame = root.CFrame + (moveDir * (configVelocidade.Dash / 60))
                GerarRastro()
            end
        end

        if VOANDO and BV and BG then
            local dir = Vector3.zero
            local movendoHorizontal = false
            local movendoVertical = false

            -- Movimentação Horizontal Baseada na Câmera
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += camera.CFrame.LookVector; movendoHorizontal = true end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= camera.CFrame.LookVector; movendoHorizontal = true end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= camera.CFrame.RightVector; movendoHorizontal = true end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += camera.CFrame.RightVector; movendoHorizontal = true end
            
            -- Movimentação Vertical (Subir/Descer) Eixos Globais
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0); movendoVertical = true end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then dir -= Vector3.new(0, 1, 0); movendoVertical = true end

            local runningSound = root:FindFirstChild("Running")
            if runningSound and runningSound:IsA("Sound") then runningSound.Volume = 0 end

            if dir.Magnitude > 0 then
                BV.Velocity = dir.Unit * configVelocidade.Fly
                
                local usarAnimVertical = movendoVertical and not movendoHorizontal

                -- CORREÇÃO DO EIXO (BodyGyro)
                if usarAnimVertical then
                    -- Se estiver apenas subindo/descendo, não inclina para frente
                    BG.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector)
                else
                    -- Voando para frente, mantém a inclinação de -15 graus
                    BG.CFrame = CFrame.new(root.Position, root.Position + camera.CFrame.LookVector) * CFrame.Angles(math.rad(-15), 0, 0)
                end
                
                GerarRastro()
                emMovimento = true
                
                -- INTEGRAÇÃO COM EMOTES: Bloqueia animação do fly se um emote estiver ativo
                if isEmotingGlobally then
                    if TrackCorrida and TrackCorrida.IsPlaying then TrackCorrida:Stop(0.1) end
                    if TrackVertical and TrackVertical.IsPlaying then TrackVertical:Stop(0.1) end
                    if TrackParado and TrackParado.IsPlaying then TrackParado:Stop(0.1) end
                else
                    if usarAnimVertical then
                        if TrackCorrida and TrackCorrida.IsPlaying then TrackCorrida:Stop(0.1) end
                        if TrackParado and TrackParado.IsPlaying then TrackParado:Stop(0.1) end
                        if TrackVertical and not TrackVertical.IsPlaying then TrackVertical:Play(0.1) end
                    else
                        if TrackVertical and TrackVertical.IsPlaying then TrackVertical:Stop(0.1) end
                        if TrackParado and TrackParado.IsPlaying then TrackParado:Stop(0.1) end
                        if TrackCorrida and not TrackCorrida.IsPlaying then TrackCorrida:Play(0.1) end
                    end
                end
            else
                BV.Velocity = Vector3.zero; BG.CFrame = camera.CFrame
                if emMovimento then
                    emMovimento = false
                end
                
                -- INTEGRAÇÃO COM EMOTES: Respeita o Emote quando estiver parado no ar
                if isEmotingGlobally then
                    if TrackCorrida and TrackCorrida.IsPlaying then TrackCorrida:Stop(0.1) end
                    if TrackVertical and TrackVertical.IsPlaying then TrackVertical:Stop(0.1) end
                    if TrackParado and TrackParado.IsPlaying then TrackParado:Stop(0.1) end
                else
                    if TrackCorrida and TrackCorrida.IsPlaying then TrackCorrida:Stop(0.1) end
                    if TrackVertical and TrackVertical.IsPlaying then TrackVertical:Stop(0.1) end
                    if TrackParado and not TrackParado.IsPlaying then TrackParado:Play(0.1) end
                end
            end
        end
    end))

    table.insert(conexoesParaLimpar, RunService.Heartbeat:Connect(function(dt)
        if ID_EXECUCAO ~= _G.VersaoAtual then return end
        local char, hum, root = ObterComponentes()
        if not root or not hum or isInvisible then return end

        if UserInputService:IsKeyDown(Enum.KeyCode.J) then targetSpeed = math.min(600, targetSpeed + (150 * dt))
        elseif UserInputService:IsKeyDown(Enum.KeyCode.H) then targetSpeed = math.max(1, targetSpeed - (150 * dt)) end
        
        if not VOANDO then hum.WalkSpeed = math.floor(targetSpeed) end

        local soundPart = root:FindFirstChild("Running")
        if waterActive then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char, plataformaAgua}
            
            local resultadoRay = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
            if resultadoRay and resultadoRay.Material == Enum.Material.Water then
                if not plataformaAgua or not plataformaAgua.Parent then
                    plataformaAgua = Instance.new("Part")
                    plataformaAgua.Size = Vector3.new(25, 1, 25)
                    plataformaAgua.Transparency = 1; plataformaAgua.Anchored = true
                    plataformaAgua.Parent = workspace
                end
                plataformaAgua.CanCollide = true
                plataformaAgua.Position = Vector3.new(root.Position.X, resultadoRay.Position.Y - 0.4, root.Position.Z)
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
                
                if soundPart and soundPart:IsA("Sound") then
                    if soundPart.SoundId ~= WATER_STEP_SOUND then
                        originalSound = originalSound or soundPart.SoundId
                        originalPitch = originalPitch or soundPart.PlaybackSpeed
                        soundPart.SoundId = WATER_STEP_SOUND
                        soundPart.Volume = 0.65
                    end
                    soundPart.PlaybackSpeed = math.clamp(hum.WalkSpeed / 80, 0.8, 1.6)
                end
            else
                if plataformaAgua and pcall(function() return plataformaAgua.Parent end) then
                    plataformaAgua.CanCollide = false; plataformaAgua.Position = Vector3.new(0, -1000, 0)
                end
                hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
                if soundPart and soundPart:IsA("Sound") and originalSound then
                    soundPart.SoundId = originalSound; soundPart.PlaybackSpeed = originalPitch; soundPart.Volume = 0.5
                    originalSound = nil
                end
            end
        else
            if plataformaAgua and pcall(function() return plataformaAgua.Parent end) then
                plataformaAgua.CanCollide = false; plataformaAgua.Position = Vector3.new(0, -1000, 0)
            end
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true) end
            if soundPart and soundPart:IsA("Sound") and originalSound then
                soundPart.SoundId = originalSound; soundPart.PlaybackSpeed = originalPitch; soundPart.Volume = 0.5
                originalSound = nil
            end
        end
    end))

    table.insert(conexoesParaLimpar, Players.PlayerAdded:Connect(updateList))
    table.insert(conexoesParaLimpar, Players.PlayerRemoving:Connect(updateList))

    local function VincularPuloDuplo(novoChar)
        if not novoChar or ID_EXECUCAO ~= _G.VersaoAtual then return end
        local hum = novoChar:WaitForChild("Humanoid", 5)
        if not hum then return end
        podePularDuplo = false; jaPuloDuplo = false

        table.insert(conexoesParaLimpar, hum.StateChanged:Connect(function(_, novoEstado)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if novoEstado == Enum.HumanoidStateType.Landed then podePularDuplo = false; jaPuloDuplo = false
            elseif novoEstado == Enum.HumanoidStateType.Freefall then podePularDuplo = true end
        end))
    end

    table.insert(conexoesParaLimpar, player.CharacterAdded:Connect(function(nc)
        task.wait(0.15); VincularPuloDuplo(nc)
        local _, newHum = ObterComponentes()
        if newHum then CarregarAnimacoes(newHum) end
    end))
    
    if player.Character then VincularPuloDuplo(player.Character) end

    table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or ID_EXECUCAO ~= _G.VersaoAtual or VOANDO or isNoclip then return end
        if input.KeyCode == Enum.KeyCode.Space and podePularDuplo and not jaPuloDuplo then
            local _, hum, root = ObterComponentes()
            if hum and root then
                jaPuloDuplo = true
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                root.Velocity = Vector3.new(root.Velocity.X, FORCA_PULO_EXTRA, root.Velocity.Z)
            end
        end
    end))

    local arrastarMenu, menuStart, uiStart
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastarMenu = true; menuStart = i.Position; uiStart = mainFrame.Position
        end
    end)
    table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(i)
        if arrastarMenu and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - menuStart
            mainFrame.Position = UDim2.new(uiStart.X.Scale, uiStart.X.Offset + delta.X, uiStart.Y.Scale, uiStart.Y.Offset + delta.Y)
        end
    end))
    table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then arrastarMenu = false end end))

    refreshBtn.MouseButton1Click:Connect(updateList)
    searchBar:GetPropertyChangedSignal("Text"):Connect(updateList)

   -- [INÍCIO DA ADIÇÃO: TARGETER]
    local btnTARGETER = criarBotaoMenu("TARGETER", 375, Color3.fromRGB(0, 255, 255))

    do
        local AlvoSelecionado = nil
        local ModoSelecaoAtivo = false
        local ModoSeguirAtivo = false
        local TargetPainelVisivel = false
        
        -- VARIÁVEIS DE EIXO/POSIÇÃO
        local OffsetRelativo = CFrame.new(0, 0, 3)
        local AjusteWASDAtivo = true
        local ModoRotacaoAtivo = false 
        
        -- AJUSTES DE VELOCIDADE
        local SensibilidadeMovimento = 2 
        local SensibilidadeRotacao = 60 

        -- CONTAINER PRINCIPAL
        local TargetMainPanel = Instance.new("Frame")
        TargetMainPanel.Size = UDim2.new(0, 270, 0, 295) 
        TargetMainPanel.Position = UDim2.new(1.05, 0, 0.4, 0) 
        TargetMainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20) 
        TargetMainPanel.BorderSizePixel = 0
        TargetMainPanel.Visible = false
        TargetMainPanel.Active = true 
        TargetMainPanel.Parent = mainFrame
        Instance.new("UICorner", TargetMainPanel).CornerRadius = UDim.new(0, 8)

        local PanelStroke = Instance.new("UIStroke")
        PanelStroke.Color = Color3.fromRGB(0, 255, 255)
        PanelStroke.Thickness = 1.5 
        PanelStroke.Parent = TargetMainPanel

        -- SISTEMA PARA ARRASTAR O PAINEL (DRAGGABLE)
        local dragging, dragInput, dragStart, startPos
        TargetMainPanel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = TargetMainPanel.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        TargetMainPanel.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                TargetMainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        -- Organização Interna
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Parent = TargetMainPanel
        ListLayout.Padding = UDim.new(0, 8) 
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local Padding = Instance.new("UIPadding")
        Padding.Parent = TargetMainPanel
        Padding.PaddingTop = UDim.new(0, 15)
        Padding.PaddingBottom = UDim.new(0, 15)
        Padding.PaddingLeft = UDim.new(0, 15)
        Padding.PaddingRight = UDim.new(0, 15)

        -- ELEMENTOS DO CORPO DO PAINEL
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 22)
        Title.Text = "TARGET COMPONENT"
        Title.TextColor3 = Color3.fromRGB(0, 255, 255)
        Title.BackgroundTransparency = 1
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 14
        Title.LayoutOrder = 1
        Title.Parent = TargetMainPanel

        local StatusLabel = Instance.new("TextLabel")
        StatusLabel.Size = UDim2.new(1, 0, 0, 18)
        StatusLabel.Text = "Status: Aguardando Alvo"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Font = Enum.Font.GothamMedium
        StatusLabel.TextSize = 12
        StatusLabel.TextWrapped = true 
        StatusLabel.LayoutOrder = 2
        StatusLabel.Parent = TargetMainPanel

        -- FUNÇÃO PARA CRIAR BOTÕES PADRONIZADOS COM BORDA
        local function CriarBotaoComBorda(nome, texto, corTexto, ordem)
            local btn = Instance.new("TextButton")
            btn.Name = nome
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
            btn.Text = texto
            btn.TextColor3 = corTexto
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 12
            btn.TextWrapped = true
            btn.BorderSizePixel = 0
            btn.LayoutOrder = ordem
            btn.Parent = TargetMainPanel
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(45, 45, 55)
            stroke.Thickness = 1
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            stroke.Parent = btn
            
            return btn, stroke
        end

        local TargetInput = Instance.new("TextBox")
        TargetInput.Size = UDim2.new(1, 0, 0, 34)
        TargetInput.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        TargetInput.PlaceholderText = "Digitar nome do jogador..."
        TargetInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 100)
        TargetInput.Text = ""
        TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        TargetInput.Font = Enum.Font.Gotham
        TargetInput.TextSize = 12
        TargetInput.TextWrapped = true
        TargetInput.BorderSizePixel = 0
        TargetInput.LayoutOrder = 3
        TargetInput.Parent = TargetMainPanel
        Instance.new("UICorner", TargetInput).CornerRadius = UDim.new(0, 6)
        
        local InputStroke = Instance.new("UIStroke")
        InputStroke.Color = Color3.fromRGB(60, 60, 75)
        InputStroke.Thickness = 1
        InputStroke.Parent = TargetInput

        local SelectBtn, SelectStroke = CriarBotaoComBorda("SelectBtn", "Selecionar por Clique: OFF", Color3.fromRGB(200, 200, 205), 4)

        -- SISTEMA DE PRESETS DE EIXO RÁPIDO
        local PresetsEixo = {
            {Nome = "Atrás (Padrão)", Offset = CFrame.new(0, 0, 3)},
            {Nome = "Na Cabeça", Offset = CFrame.new(0, 3.5, 0)},
            {Nome = "Ombro Direito", Offset = CFrame.new(1.5, 2.5, 0)},
            {Nome = "Ombro Esquerdo", Offset = CFrame.new(-1.5, 2.5, 0)},
            {Nome = "Nas Costas", Offset = CFrame.new(0, 0.5, 1.2)},
            {Nome = "Na Frente", Offset = CFrame.new(0, 0, -1.5)},
            {Nome = "Customizado (WASD)", Offset = CFrame.new(0, 0, 3)} 
        }
        local PresetIndex = 1

        local PresetBtn, PresetStroke = CriarBotaoComBorda("PresetBtn", "Eixo: " .. PresetsEixo[PresetIndex].Nome, Color3.fromRGB(0, 255, 255), 5)
        local WasdBtn, WasdStroke = CriarBotaoComBorda("WasdBtn", "Ajuste Dinâmico (WASD): ON", Color3.fromRGB(0, 255, 150), 6)
        
        local ResetBtn, ResetStroke = CriarBotaoComBorda("ResetBtn", "RESET", Color3.fromRGB(255, 100, 100), 7)
        ResetBtn.TextSize = 6
        ResetBtn.Font = Enum.Font.GothamBlack
        ResetStroke.Color = Color3.fromRGB(120, 30, 30)

        -- Lista de sugestões
        local SuggestionList = Instance.new("ScrollingFrame")
        SuggestionList.Size = UDim2.new(1, 0, 0, 110)
        SuggestionList.Position = UDim2.new(0, 0, 1, 4)
        SuggestionList.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        SuggestionList.BorderSizePixel = 0
        SuggestionList.Visible = false
        SuggestionList.ScrollBarThickness = 3
        SuggestionList.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
        SuggestionList.ZIndex = 5
        SuggestionList.Parent = TargetInput
        Instance.new("UICorner", SuggestionList).CornerRadius = UDim.new(0, 5)
        
        local SugStroke = Instance.new("UIStroke")
        SugStroke.Color = Color3.fromRGB(0, 255, 255)
        SugStroke.Thickness = 1
        SugStroke.Parent = SuggestionList

        local UIList = Instance.new("UIListLayout", SuggestionList)
        UIList.Padding = UDim.new(0, 4)

        -- INTERAÇÕES E LÓGICA
        local function SetAlvo(p)
            if p and p.Character then
                AlvoSelecionado = p
                StatusLabel.Text = "Alvo: " .. p.DisplayName
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                SuggestionList.Visible = false
                TargetInput.Text = ""
                ModoRotacaoAtivo = false
            end
        end

        table.insert(conexoesParaLimpar, PresetBtn.MouseButton1Click:Connect(function()
            PresetIndex = PresetIndex + 1
            if PresetIndex > #PresetsEixo then PresetIndex = 1 end
            
            OffsetRelativo = PresetsEixo[PresetIndex].Offset
            PresetBtn.Text = "Eixo: " .. PresetsEixo[PresetIndex].Nome
            
            if PresetIndex == 7 then
                PresetBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
                PresetStroke.Color = Color3.fromRGB(120, 90, 20)
            else
                PresetBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
                PresetStroke.Color = Color3.fromRGB(45, 45, 55)
            end
            
            ModoRotacaoAtivo = false
        end))

        table.insert(conexoesParaLimpar, ResetBtn.MouseButton1Click:Connect(function()
            PresetsEixo[7].Offset = CFrame.new(0, 0, 3) 
            if PresetIndex == 7 then
                OffsetRelativo = PresetsEixo[7].Offset
                ModoRotacaoAtivo = false
            end
            
            ResetBtn.Text = "EIXO ZERADO"
            ResetBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            task.delay(1.5, function()
                ResetBtn.Text = "RESET"
                ResetBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
            end)
        end))

        table.insert(conexoesParaLimpar, WasdBtn.MouseButton1Click:Connect(function()
            AjusteWASDAtivo = not AjusteWASDAtivo
            WasdBtn.Text = AjusteWASDAtivo and "Ajuste Dinâmico (WASD): ON" or "Ajuste Dinâmico (WASD): OFF"
            WasdBtn.TextColor3 = AjusteWASDAtivo and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
            WasdStroke.Color = AjusteWASDAtivo and Color3.fromRGB(0, 100, 50) or Color3.fromRGB(100, 20, 20)
        end))

        table.insert(conexoesParaLimpar, TargetInput:GetPropertyChangedSignal("Text"):Connect(function()
            local busca = TargetInput.Text:lower()
            for _, child in pairs(SuggestionList:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            
            if busca == "" then SuggestionList.Visible = false return end
            
            local encontrados = 0
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and (p.Name:lower():find(busca) or p.DisplayName:lower():find(busca)) then
                    encontrados = encontrados + 1
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, -8, 0, 28)
                    btn.Position = UDim2.new(0, 4, 0, 0)
                    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
                    btn.Text = "  " .. p.DisplayName
                    btn.TextColor3 = Color3.fromRGB(230, 230, 235)
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 11
                    btn.BorderSizePixel = 0
                    btn.ZIndex = 6
                    btn.Parent = SuggestionList
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
                    
                    local selLabel = Instance.new("TextLabel", btn)
                    selLabel.Size = UDim2.new(0, 50, 1, 0)
                    selLabel.Position = UDim2.new(1, -55, 0, 0)
                    selLabel.Text = "SELECT"
                    selLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
                    selLabel.BackgroundTransparency = 1
                    selLabel.Font = Enum.Font.GothamBold
                    selLabel.TextSize = 9
                    selLabel.ZIndex = 7
                    
                    table.insert(conexoesParaLimpar, btn.MouseButton1Click:Connect(function() SetAlvo(p) end))
                end
            end
            
            if encontrados > 0 then
                SuggestionList.Visible = true
                SuggestionList.CanvasSize = UDim2.new(0, 0, 0, encontrados * 32)
            else
                SuggestionList.Visible = false
            end
        end))

        table.insert(conexoesParaLimpar, btnTARGETER.MouseButton1Click:Connect(function()
            TargetPainelVisivel = not TargetPainelVisivel
            TargetMainPanel.Visible = TargetPainelVisivel
            btnTARGETER.BackgroundColor3 = TargetPainelVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnTARGETER.TextColor3 = TargetPainelVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 150)
        end))

        table.insert(conexoesParaLimpar, SelectBtn.MouseButton1Click:Connect(function()
            ModoSelecaoAtivo = not ModoSelecaoAtivo
            SelectBtn.Text = ModoSelecaoAtivo and "Selecionar por Clique: ON" or "Selecionar por Clique: OFF"
            SelectBtn.TextColor3 = ModoSelecaoAtivo and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(200, 200, 205)
            SelectStroke.Color = ModoSelecaoAtivo and Color3.fromRGB(0, 100, 100) or Color3.fromRGB(45, 45, 55)
        end))

        table.insert(conexoesParaLimpar, mouse.Button1Down:Connect(function()
            if ModoSelecaoAtivo then
                mouse.TargetFilter = player.Character
                local t = mouse.Target
                if t and t.Parent then
                    local char = t.Parent:FindFirstChild("Humanoid") and t.Parent or t.Parent.Parent
                    if char:FindFirstChild("Humanoid") then
                        local p = Players:GetPlayerFromCharacter(char)
                        if p and p ~= player then SetAlvo(p) end
                    end
                end
            end
        end))

        table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if UserInputService:GetFocusedTextBox() then return end
            
            if input.KeyCode == Enum.KeyCode.CapsLock then
                ModoRotacaoAtivo = not ModoRotacaoAtivo
                if ModoRotacaoAtivo then
                    PresetBtn.Text = "Eixo: MODO ROTAÇÃO"
                    PresetBtn.TextColor3 = Color3.fromRGB(255, 105, 180) 
                    PresetStroke.Color = Color3.fromRGB(150, 40, 100)
                else
                    if PresetIndex == 7 then
                        PresetBtn.Text = "Eixo: Customizado (WASD)"
                        PresetBtn.TextColor3 = Color3.fromRGB(255, 200, 50) 
                        PresetStroke.Color = Color3.fromRGB(120, 90, 20)
                    else
                        PresetBtn.Text = "Eixo: " .. PresetsEixo[PresetIndex].Nome
                        PresetBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
                        PresetStroke.Color = Color3.fromRGB(45, 45, 55)
                    end
                end
                return
            end

            -- Atalhos de Controle mantidos no Ctrl (Teleport R, Toggle Seguir T)
            local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if ctrl and AlvoSelecionado and AlvoSelecionado.Character then
                local hrpA = AlvoSelecionado.Character:FindFirstChild("HumanoidRootPart")
                local hrpM = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                
                if input.KeyCode == Enum.KeyCode.R then
                    if hrpA and hrpM then
                        hrpM.CFrame = hrpA.CFrame * OffsetRelativo
                    else
                        StatusLabel.Text = "ERRO: Muito Distante!"
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
                        task.delay(1.5, function()
                            if AlvoSelecionado then
                                StatusLabel.Text = ModoSeguirAtivo and "Seguindo: " .. AlvoSelecionado.DisplayName or "Alvo: " .. AlvoSelecionado.DisplayName
                                StatusLabel.TextColor3 = ModoSeguirAtivo and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(150, 150, 155)
                            end
                        end)
                    end
                elseif input.KeyCode == Enum.KeyCode.T then
                    ModoSeguirAtivo = not ModoSeguirAtivo
                    StatusLabel.Text = ModoSeguirAtivo and "Seguindo: " .. AlvoSelecionado.DisplayName or "Alvo: " .. AlvoSelecionado.DisplayName
                    StatusLabel.TextColor3 = ModoSeguirAtivo and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(150, 150, 155)
                end
            end
        end))

        table.insert(conexoesParaLimpar, RunService.Heartbeat:Connect(function(dt)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if ModoSeguirAtivo and AlvoSelecionado and AlvoSelecionado.Character then
                local hrpA = AlvoSelecionado.Character:FindFirstChild("HumanoidRootPart")
                local meuHrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                
                if hrpA and meuHrp then
                    StatusLabel.Text = ModoRotacaoAtivo and "Girando Eixo: " .. AlvoSelecionado.DisplayName or "Seguindo: " .. AlvoSelecionado.DisplayName
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                    
                    if AjusteWASDAtivo and not UserInputService:GetFocusedTextBox() then
                        if not ModoRotacaoAtivo then
                            local deltaX, deltaY, deltaZ = 0, 0, 0
                            local speed = SensibilidadeMovimento * dt 
                            
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then deltaZ = deltaZ - speed end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then deltaZ = deltaZ + speed end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then deltaX = deltaX - speed end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then deltaX = deltaX + speed end
                            -- Substituído Espaço por X e Ctrl por Z
                            if UserInputService:IsKeyDown(Enum.KeyCode.X) then deltaY = deltaY + speed end
                            if UserInputService:IsKeyDown(Enum.KeyCode.Z) then deltaY = deltaY - speed end
                            
                            if deltaX ~= 0 or deltaY ~= 0 or deltaZ ~= 0 then
                                OffsetRelativo = OffsetRelativo * CFrame.new(deltaX, deltaY, deltaZ)
                                
                                PresetsEixo[7].Offset = OffsetRelativo
                                PresetIndex = 7
                                
                                if PresetBtn.Text ~= "Eixo: Customizado (WASD)" then
                                    PresetBtn.Text = "Eixo: Customizado (WASD)"
                                    PresetBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
                                    PresetStroke.Color = Color3.fromRGB(120, 90, 20)
                                end
                            end
                        else
                            local rotX, rotY, rotZ = 0, 0, 0
                            local rSpeed = math.rad(SensibilidadeRotacao) * dt
                            
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then rotX = rotX + rSpeed end 
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then rotX = rotX - rSpeed end 
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then rotY = rotY + rSpeed end 
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then rotY = rotY - rSpeed end 
                            -- Substituído Espaço por X e Ctrl por Z
                            if UserInputService:IsKeyDown(Enum.KeyCode.X) then rotZ = rotZ + rSpeed end 
                            if UserInputService:IsKeyDown(Enum.KeyCode.Z) then rotZ = rotZ - rSpeed end 
                            
                            if rotX ~= 0 or rotY ~= 0 or rotZ ~= 0 then
                                OffsetRelativo = OffsetRelativo * CFrame.Angles(rotX, rotY, rotZ)
                                
                                PresetsEixo[7].Offset = OffsetRelativo
                                PresetIndex = 7
                                
                                if PresetBtn.Text ~= "Eixo: MODO ROTAÇÃO" then
                                    PresetBtn.Text = "Eixo: MODO ROTAÇÃO"
                                    PresetBtn.TextColor3 = Color3.fromRGB(255, 105, 180)
                                    PresetStroke.Color = Color3.fromRGB(150, 40, 100)
                                end
                            end
                        end
                    end
                    
                    local predicao = hrpA.CFrame + (hrpA.AssemblyLinearVelocity * 0.08)
                    meuHrp.CFrame = predicao * OffsetRelativo
                    meuHrp.AssemblyLinearVelocity = Vector3.zero 
                else
                    ModoSeguirAtivo = false
                    if StatusLabel then
                        StatusLabel.Text = "PERDIDO: Fora de Alcance"
                        StatusLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
                    end
                end
            end
        end))
    end
-- [FIM DA ADIÇÃO: TARGETER]

    -- [INÍCIO DA ADIÇÃO: SISTEMA DE EMOTES]
    local btnEMOTES = criarBotaoMenu("EMOTES", 100, Color3.fromRGB(0, 255, 255))
    btnEMOTES.Position = UDim2.new(0, -88, 0, 100)

    do
        local isEmoting = false
        local currentTrack = nil
        local forceLoop = nil
        local lastUsedId = nil
        local originalHipHeight = nil
        local EmoteScroll = nil 
        local UpdateActiveEmoteUI = nil 

        -- NOVA FLAG: controla se o sistema de emotes está habilitado
        local EmotesEnabled = true
        
        local AvatarEditorService = game:GetService("AvatarEditorService")
        local MarketplaceService = game:GetService("MarketplaceService") -- ADICIONADO PARA BUSCA DE ID
        local HttpService = game:GetService("HttpService")
        local TweenService = game:GetService("TweenService")

        -- Lista base original de Emotes MANTIDA E INTACTA
        local EmoteList = {
            ["BATER ASAS"] = 106894076202843, ["SENTAR COM APOIO"] = 96606489351695, ["CAIR PARA TRÁS 1"] = 133253034133867,
            ["DANCINHA SX"] = 120297764741811, ["MÃOS PARA CIMA"] = 108894965141226, ["ABRAÇO"] = 102303622774230,
            ["POSE SX"] = 98057692601307, ["DE JOELHOS 1"] = 130298701144678, ["DE JOELHOS 2"] = 111512384233253,
            ["CAIR PARA TRÁS 2"] = 93150267965359, ["DANCINHA DE ANIME"] = 97233973386966, ["CHUTE"] = 139593983390391,
            ["SENTAR NO AR"] = 87939646671209, ["CORTEI O CABELO"] = 101275066718933, ["SE ARRASTAR"] = 95339769038863,
            ["REVERÊNCIA 1"] = 89198573930777, ["DANÇA GROOVE"] = 85913265750993, ["DORMIR DE LADO"] = 105016815489641,
            ["TRISTE"] = 75968890183942, ["FAZER BIRRA"] = 121911959295081, ["VOAR PARADO"] = 93511411593120,
            ["ASSUSTADOR"] = 79216795769647, ["BOLA GIRATÓRIA"] = 93195109588878, ["TOMBAR PARA TRÁS"] = 140184938717896,
            ["DEITAR FOFO"] = 114695623925996, ["LEVITAR"] = 87826892596287, ["CAIR DE FRENTE"] = 89115363544461,
            ["NO CARRO"] = 17360720445, ["CONFUSO"] = 4940592718, ["DORMIR"] = 4689362868,
            ["CHAMAR"] = 5230615437, ["CELEBRAÇÃO"] = 3994127840, ["DANÇA PULANDO"] = 15610015346,
            ["CONTINÊNCIA"] = 3360689775, ["POSE DE MACACO"] = 3360692915, ["ROLO DE PESCOÇO"] = 93641632427451,
            ["FLUTUAR POR PARTES"] = 125154823571632, ["FICAR ALTO"] = 93875137466223, ["MJ DANÇA"] = 140440735589603, 
            ["CORRER LOUCO"] = 122648944421682, ["FLUTUAR SEM CABEÇA"] = 105381637724646, ["MONSTRO VIGILANTE"] = 71350324794436,
            ["SENTAR FOFO 1"] = 72947568152049, ["SENTAR FOFO 2"] = 129766891082557,  ["SENTAR FOFO 3"] = 112758073578333,
            ["MIRANHA"] = 130987133773478, ["DE COCA"] = 140187771377253, ["SENTA RELAXADO"] = 99568437064777,
            ["GOJO AURA"] = 107572993172129,["CORRIDA SONIC"] = 103737097131582, ["DEITAR DE COTOVELO"] = 98673557054097,
            ["AURA"] = 112022806707883, ["FISICULTURISTA 1"] = 74248485441791, ["QUEDA LIVRE"] = 139315033132446,
            ["ZUMBI SE ARRASTANDO"] = 86181833449310, ["RAÇOS CRUZADOS"] = 109943159588113, ["MÃO NAS COSTAS"] = 82032953832186,
            ["TAPAS RÁPIDOS"] = 135797862569526, ["MOVIMENTO SX"] = 84564562706273, ["TRISTÃO NO CHÃO"] = 95339652051393,
            ["SOCOS 1"] = 115203580644128, ["REVERÊNCIA 2"] = 72613272882226, ["DANÇA SX 1"] = 75916083282765,
            ["POSE DO MIRANHA"] = 112354510576428, ["GARGALHADA"] = 122240620529815, ["DIRIGIR"] = 114536981341323,
            ["PISADAS"] = 88598010609888, ["TRISTINHO"] = 111061988978180, ["SUPLICAR"] = 132215818991173,
            ["EMPURRAR"] = 99361714808662, ["BRAÇOS PESADOS"] = 118245561567361, ["MATRÍX"] = 126953460227212,
            ["SOCOS 2"] = 115203580644128, ["SIH"] = 72049728640815, ["ENCOSTADO"] = 118853736905967,
            ["VOAR PRA FRENTE"] = 101570135818967, ["FANTASMA"] = 75911227509248, ["MJ MOONWALK"] = 105106008516273,
            ["DANÇA SX 2"] = 106085454330405, ["INVISÍVEL"] = 101801833201272, ["CORRIDA DE BIXO 1"] = 108250142335987,
            ["TREMER NO CHÃO"] = 132844034228766, ["GIRAR EM VOLTA"] = 79391937339603, ["CORRIDA DE BIXO 2"] = 84792004932424,
            ["BALANÇAR O QUADRIL"] = 110806766469743, ["DANÇA DO JAMAL"] = 104131847054135, ["SAMBA"] = 71137067237576,
            ["CORRIDA LOUCA"] = 72726465017708, ["T-REX"] = 121516176166245, ["CORAÇÃO"] = 113903938327206,
            ["POSE DE HERÓI"] = 133313698349300, ["MÃO DE FURADEIRA"] = 103882178542598
        }

        -- SISTEMA DE SAVE DOS FAVORITOS (Salva no Executor)
        local ARQUIVO_FAVORITOS = "PainelNeon_Emotes.json"
        
        if isfile and isfile(ARQUIVO_FAVORITOS) then
            pcall(function()
                local salvos = HttpService:JSONDecode(readfile(ARQUIVO_FAVORITOS))
                for k, v in pairs(salvos) do
                    EmoteList[k] = v
                end
            end)
        end

        local function SalvarFavoritosFile()
            if writefile then
                pcall(function() writefile(ARQUIVO_FAVORITOS, HttpService:JSONEncode(EmoteList)) end)
            end
        end

        local function GetAnimationFromCatalog(id)
            local success, result = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
            if success and result and result[1] then
                if result[1]:IsA("Animation") then return result[1] end
                return result[1]:FindFirstChildOfClass("Animation", true)
            end
            return nil
        end

        local function StopEmote(isSwitching)
            isEmoting = false
            isEmotingGlobally = false -- ADICIONE ESTA LINHA
            if currentTrack then currentTrack:Stop(); currentTrack:Destroy(); currentTrack = nil end
            if forceLoop then forceLoop:Disconnect(); forceLoop = nil end

            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if hum and originalHipHeight then
                hum.HipHeight = originalHipHeight
                if root and not isSwitching then
                    root.CFrame = root.CFrame + Vector3.new(0, 1.5, 0)
                end
                if not isSwitching then originalHipHeight = nil end
            end
        end

        UpdateActiveEmoteUI = function()
            if not EmoteScroll then return end
            for _, child in pairs(EmoteScroll:GetChildren()) do
                if child:IsA("Frame") then
                    local frameId = child:GetAttribute("EmoteId")
                    local defColor = child:GetAttribute("DefaultColor")
                    
                    if frameId and defColor then
                        local targetColor = (frameId == lastUsedId) and Color3.fromRGB(46, 204, 113) or defColor
                        if child.BackgroundColor3 ~= targetColor then
                            TweenService:Create(child, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
                        end
                    end
                end
            end
        end

        local function PlayEmote(id)
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local anim = hum and hum:FindFirstChildOfClass("Animator")
            if not anim then return end

            if not originalHipHeight then originalHipHeight = hum.HipHeight end

            lastUsedId = id
            UpdateActiveEmoteUI() 
            StopEmote(true)

            if id == 86181833449310 then hum.HipHeight = 2.30
            else hum.HipHeight = originalHipHeight end
            
            local animObj = GetAnimationFromCatalog(id)
            if not animObj then return end

            currentTrack = anim:LoadAnimation(animObj)
            currentTrack.Priority = Enum.AnimationPriority.Action4
            currentTrack.Looped = true
            currentTrack:Play()
            isEmoting = true
            isEmotingGlobally = true -- ADICIONE ESTA LINHA AQUI

            forceLoop = RunService.Heartbeat:Connect(function()
                if ID_EXECUCAO ~= _G.VersaoAtual then
                    if forceLoop then forceLoop:Disconnect() end
                    return
                end
                if isEmoting and currentTrack then
                    if not currentTrack.IsPlaying then currentTrack:Play() end
                    currentTrack:AdjustWeight(1)
                end
            end)
            table.insert(conexoesParaLimpar, forceLoop)
        end

        local EmotePainelVisivel = false
        
        -- INTERFACE APERFEIÇOADA
        local EmoteMainPanel = Instance.new("Frame")
        EmoteMainPanel.Size = UDim2.new(0, 370, 0, 540) 
        EmoteMainPanel.Position = UDim2.new(0.5, -185, 0.5, -270)
        EmoteMainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        EmoteMainPanel.BackgroundTransparency = 0.1
        EmoteMainPanel.BorderSizePixel = 0
        EmoteMainPanel.Visible = false
        EmoteMainPanel.Active = true
        EmoteMainPanel.Parent = screenGui 
        Instance.new("UICorner", EmoteMainPanel).CornerRadius = UDim.new(0, 12)
        local panelStroke = Instance.new("UIStroke", EmoteMainPanel)
        panelStroke.Color = Color3.fromRGB(0, 255, 255)
        panelStroke.Thickness = 2
        panelStroke.Transparency = 0.3

        local arrastarEmote, emoteStart, uiEmoteStart
        EmoteMainPanel.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                arrastarEmote = true; emoteStart = i.Position; uiEmoteStart = EmoteMainPanel.Position
            end
        end)
        table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(i)
            if arrastarEmote and i.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = i.Position - emoteStart
                EmoteMainPanel.Position = UDim2.new(uiEmoteStart.X.Scale, uiEmoteStart.X.Offset + delta.X, uiEmoteStart.Y.Scale, uiEmoteStart.Y.Offset + delta.Y)
            end
        end))
        table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then arrastarEmote = false end
        end))

        local EmoteTitle = Instance.new("TextLabel", EmoteMainPanel)
        EmoteTitle.Size = UDim2.new(1, 0, 0, 40)
        EmoteTitle.Text = "EMOTES MENU [CTRL+B]"
        EmoteTitle.Font = Enum.Font.GothamBlack
        EmoteTitle.TextSize = 16
        EmoteTitle.TextColor3 = Color3.new(1, 1, 1)
        EmoteTitle.BackgroundTransparency = 1

        local SearchBox = Instance.new("TextBox", EmoteMainPanel)
        SearchBox.Size = UDim2.new(0.9, 0, 0, 32)
        SearchBox.Position = UDim2.new(0.05, 0, 0, 45)
        SearchBox.PlaceholderText = "Pesquisar emote ou colar ID..."
        SearchBox.Text = ""
        SearchBox.Font = Enum.Font.GothamSemibold
        SearchBox.TextSize = 13
        SearchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        SearchBox.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
        local searchStroke = Instance.new("UIStroke", SearchBox)
        searchStroke.Color = Color3.fromRGB(60, 60, 70)
        searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local OnlineSearchBtn = Instance.new("TextButton", EmoteMainPanel)
        OnlineSearchBtn.Size = UDim2.new(0.9, 0, 0, 30) 
        OnlineSearchBtn.Position = UDim2.new(0.05, 0, 0, 85)
        OnlineSearchBtn.Text = "PESQUISAR ONLINE 🌐"
        OnlineSearchBtn.Font = Enum.Font.GothamBold
        OnlineSearchBtn.TextSize = 13
        OnlineSearchBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 225)
        OnlineSearchBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", OnlineSearchBtn).CornerRadius = UDim.new(0, 6)

        local ReturnFavsBtn = Instance.new("TextButton", EmoteMainPanel)
        ReturnFavsBtn.Size = UDim2.new(0.9, 0, 0, 30) 
        ReturnFavsBtn.Position = UDim2.new(0.05, 0, 0, 122) 
        ReturnFavsBtn.Text = "VOLTAR AOS FAVORITOS"
        ReturnFavsBtn.Font = Enum.Font.GothamBold
        ReturnFavsBtn.TextSize = 13
        ReturnFavsBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
        ReturnFavsBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", ReturnFavsBtn).CornerRadius = UDim.new(0, 6)

        EmoteScroll = Instance.new("ScrollingFrame", EmoteMainPanel)
        EmoteScroll.Size = UDim2.new(0.92, 0, 1, -215) 
        EmoteScroll.Position = UDim2.new(0.04, 0, 0, 160) 
        EmoteScroll.BackgroundTransparency = 1
        EmoteScroll.ScrollBarThickness = 5
        EmoteScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255)
        EmoteScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        EmoteScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UIListLayout", EmoteScroll).Padding = UDim.new(0, 6)

        -- Função CriarItemNaLista com UI Melhorada
        local function CriarItemNaLista(nome, id, corFundo)
            local itemFrame = Instance.new("Frame", EmoteScroll)
            itemFrame.Name = nome
            itemFrame.Size = UDim2.new(1, -6, 0, 38)
            itemFrame.BackgroundColor3 = (id == lastUsedId) and Color3.fromRGB(46, 204, 113) or corFundo
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)

            itemFrame:SetAttribute("EmoteId", id)
            itemFrame:SetAttribute("DefaultColor", corFundo)

            local playBtn = Instance.new("TextButton", itemFrame)
            playBtn.Size = UDim2.new(1, -110, 1, 0)
            playBtn.BackgroundTransparency = 1
            playBtn.Text = "  " .. nome
            playBtn.TextXAlignment = Enum.TextXAlignment.Left
            playBtn.Font = Enum.Font.GothamMedium
            playBtn.TextSize = 13
            playBtn.TextColor3 = Color3.new(1, 1, 1)
            playBtn.TextTruncate = Enum.TextTruncate.AtEnd

            local isFavorited = EmoteList[nome] ~= nil
            local favBtn = Instance.new("TextButton", itemFrame)
            favBtn.Size = UDim2.new(0, 35, 0, 38)
            favBtn.Position = UDim2.new(1, -38, 0, 0)
            favBtn.BackgroundTransparency = 1
            favBtn.Text = isFavorited and "★" or "☆"
            favBtn.TextSize = 22
            favBtn.TextColor3 = isFavorited and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
            favBtn.Font = Enum.Font.GothamBold

            local copyBtn = Instance.new("TextButton", itemFrame)
            copyBtn.Size = UDim2.new(0, 55, 0, 38)
            copyBtn.Position = UDim2.new(1, -95, 0, 0)
            copyBtn.BackgroundTransparency = 1
            copyBtn.Text = "COPIAR"
            copyBtn.TextSize = 11
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)

            table.insert(conexoesParaLimpar, playBtn.MouseButton1Click:Connect(function() PlayEmote(id) end))

            table.insert(conexoesParaLimpar, favBtn.MouseButton1Click:Connect(function()
                if EmoteList[nome] then
                    EmoteList[nome] = nil
                    favBtn.Text = "☆"
                    favBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                else
                    EmoteList[nome] = id
                    favBtn.Text = "★"
                    favBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
                SalvarFavoritosFile()
            end))

            table.insert(conexoesParaLimpar, copyBtn.MouseButton1Click:Connect(function()
                local idStr = tostring(id or "")
                local ok = false

                pcall(function()
                    if setclipboard then
                        setclipboard(idStr)
                        ok = true
                        return
                    end
                    local GuiService = game:GetService("GuiService")
                    if GuiService and GuiService.SetClipboard then
                        GuiService:SetClipboard(idStr)
                        ok = true
                        return
                    end
                end)

                if ok then
                    local prevText = copyBtn.Text
                    copyBtn.Text = "COPIADO!"
                    copyBtn.TextColor3 = Color3.fromRGB(46, 204, 113)
                    task.delay(1.5, function()
                        if copyBtn and copyBtn.Parent then
                            copyBtn.Text = prevText
                            copyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                        end
                    end)
                else
                    local prevText = copyBtn.Text
                    copyBtn.Text = "ERRO"
                    copyBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                    task.delay(1.5, function()
                        if copyBtn and copyBtn.Parent then
                            copyBtn.Text = prevText
                            copyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                        end
                    end)
                end
            end))
        end

        local function CarregarFavoritosUI()
            for _, child in pairs(EmoteScroll:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end

            local sortedNames = {}
            for name in pairs(EmoteList) do table.insert(sortedNames, name) end
            table.sort(sortedNames)

            for _, name in ipairs(sortedNames) do
                CriarItemNaLista(name, EmoteList[name], Color3.fromRGB(30, 30, 35))
            end
        end

        CarregarFavoritosUI() 

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            local query = SearchBox.Text:upper()
            if query == "" then CarregarFavoritosUI() return end
            
            for _, item in pairs(EmoteScroll:GetChildren()) do
                if item:IsA("Frame") then
                    item.Visible = string.find(item.Name:upper(), query) ~= nil
                end
            end
        end)

        table.insert(conexoesParaLimpar, ReturnFavsBtn.MouseButton1Click:Connect(function()
            SearchBox.Text = ""
            CarregarFavoritosUI()
        end))

        -- NOVA LÓGICA DE BUSCA: Mais resultados e Ordenação Inteligente
        table.insert(conexoesParaLimpar, OnlineSearchBtn.MouseButton1Click:Connect(function()
            local query = SearchBox.Text
            query = query:match("^%s*(.-)%s*$")
            
            if query == "" then
                OnlineSearchBtn.Text = "DIGITE ALGO PRIMEIRO!"
                task.wait(1.5)
                OnlineSearchBtn.Text = "PESQUISAR ONLINE 🌐"
                return
            end

            OnlineSearchBtn.Text = "BUSCANDO..."
            
            task.spawn(function()
                local isId = tonumber(query) 

                if isId then
                    -- BUSCA POR ID
                    local success, info = pcall(function()
                        return MarketplaceService:GetProductInfo(isId, Enum.InfoType.Asset)
                    end)

                    if success and info then
                        for _, child in pairs(EmoteScroll:GetChildren()) do
                            if child:IsA("Frame") then child:Destroy() end
                        end
                        local emoteName = info.Name or ("Emote ID: " .. isId)
                        CriarItemNaLista(emoteName, isId, Color3.fromRGB(80, 20, 150))
                        OnlineSearchBtn.Text = "ID ENCONTRADO ✅"
                    else
                        OnlineSearchBtn.Text = "ID INVÁLIDO"
                    end

                else
                    -- BUSCA EXPANDIDA POR PALAVRA (ATÉ 400 RESULTADOS)
                    local success, paginas = pcall(function()
                        local params = CatalogSearchParams.new()
                        params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
                        params.SearchKeyword = query
                        params.SortType = Enum.CatalogSortType.Relevance
                        return AvatarEditorService:SearchCatalog(params)
                    end)

                    if success and paginas then
                        local allResults = {}
                        local maxItems = 400 -- Limite expandido solicitado
                        
                        -- Loop para buscar múltiplas páginas em background
                        while #allResults < maxItems do
                            local currentPage = paginas:GetCurrentPage()
                            for _, item in ipairs(currentPage) do
                                table.insert(allResults, item)
                            end
                            
                            if paginas.IsFinished or #allResults >= maxItems then break end
                            
                            local advSuccess = pcall(function()
                                paginas:AdvanceToNextPageAsync()
                            end)
                            if not advSuccess then break end
                        end

                        if #allResults == 0 then
                            OnlineSearchBtn.Text = "NADA ENCONTRADO"
                        else
                            -- Ordenação Inteligente para burlar tradução ruim
                            local qLower = query:lower()
                            table.sort(allResults, function(a, b)
                                local nameA, nameB = a.Name:lower(), b.Name:lower()
                                
                                -- 1. Prioridade Máxima: Nome Exato
                                local aExact = (nameA == qLower)
                                local bExact = (nameB == qLower)
                                if aExact ~= bExact then return aExact end
                                
                                -- 2. Prioridade Alta: Começa com a palavra
                                local aStarts = (string.sub(nameA, 1, #qLower) == qLower)
                                local bStarts = (string.sub(nameB, 1, #qLower) == qLower)
                                if aStarts ~= bStarts then return aStarts end
                                
                                -- 3. Prioridade Média: Contém a palavra inteira isolada
                                local aFind = (string.find(nameA, "%f[%w]"..qLower.."%f[%W]") ~= nil)
                                local bFind = (string.find(nameB, "%f[%w]"..qLower.."%f[%W]") ~= nil)
                                if aFind ~= bFind then return aFind end
                                
                                -- 4. Desempate Alfabético
                                return nameA < nameB
                            end)

                            for _, child in pairs(EmoteScroll:GetChildren()) do
                                if child:IsA("Frame") then child:Destroy() end
                            end

                            -- Renderizar os resultados ordenados
                            for _, item in ipairs(allResults) do
                                CriarItemNaLista(item.Name, item.Id, Color3.fromRGB(60, 25, 120))
                            end
                            OnlineSearchBtn.Text = "ENCONTRADOS: " .. #allResults .. " ✅"
                        end
                    else
                        OnlineSearchBtn.Text = "ERRO NA BUSCA"
                    end
                end

                task.wait(2)
                OnlineSearchBtn.Text = "PESQUISAR ONLINE 🌐"
            end)
        end))

        local StopBtn = Instance.new("TextButton", EmoteMainPanel)
        StopBtn.Size = UDim2.new(0.9, 0, 0, 42)
        StopBtn.Position = UDim2.new(0.05, 0, 1, -48)
        StopBtn.Text = "PARAR / RETOMAR"
        StopBtn.Font = Enum.Font.GothamBlack
        StopBtn.TextSize = 14
        StopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        StopBtn.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)

        table.insert(conexoesParaLimpar, StopBtn.MouseButton1Click:Connect(function()
            if isEmoting then StopEmote(false)
            elseif lastUsedId then PlayEmote(lastUsedId) end
        end))

        table.insert(conexoesParaLimpar, btnEMOTES.MouseButton1Click:Connect(function()
            EmotePainelVisivel = not EmotePainelVisivel
            EmoteMainPanel.Visible = EmotePainelVisivel
            btnEMOTES.BackgroundColor3 = EmotePainelVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnEMOTES.TextColor3 = EmotePainelVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        end))

        -- SUBSTITUIÇÃO ISOLADA: novo handler InputBegan com toggle Shift+Ctrl+B
        table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gpe)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if UserInputService:GetFocusedTextBox() then return end
            
            if input.KeyCode == Enum.KeyCode.B then
                local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
                local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

                -- Toggle global de ativação/desativação com Shift + Ctrl + B
                if ctrl and shift then
                    EmotesEnabled = not EmotesEnabled

                    -- Feedback visual mínimo
                    EmoteTitle.Text = "EMOTES MENU [CTRL+B]" .. (EmotesEnabled and "" or " (DESATIVADO)")

                    -- Ao desativar, garanta que qualquer emote em execução seja parado e o painel fechado
                    if not EmotesEnabled then
                        if isEmoting then
                            StopEmote(false)
                        end
                        EmotePainelVisivel = false
                        EmoteMainPanel.Visible = false
                        btnEMOTES.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
                        btnEMOTES.TextColor3 = Color3.fromRGB(0, 255, 255)
                    end

                    return -- interrompe aqui para não executar o comportamento normal do B
                end

                -- Se o sistema estiver desativado, ignorar pressionamentos simples de B
                if not EmotesEnabled then
                    return
                end

                -- Comportamento original quando apenas B é pressionado
                if ctrl then
                    EmotePainelVisivel = not EmotePainelVisivel
                    EmoteMainPanel.Visible = EmotePainelVisivel
                    btnEMOTES.BackgroundColor3 = EmotePainelVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
                    btnEMOTES.TextColor3 = EmotePainelVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
                else
                    if isEmoting then StopEmote(false)
                    elseif lastUsedId then PlayEmote(lastUsedId) end
                end
            end
        end))
    end
-- [FIM DA ADIÇÃO: SISTEMA DE EMOTES]
    -- [INÍCIO DA ADIÇÃO: ANIMATION CHANGER UNIFICADO]
    local btnANIM = criarBotaoMenu("ANIMAÇÕES", 155, Color3.fromRGB(0, 255, 255))
    btnANIM.Position = UDim2.new(0, -88, 0, 155)

    do
        local AnimTheme = {
            Background = Color3.fromRGB(15, 15, 25), NeonCyan = Color3.fromRGB(0, 255, 255), NeonPink = Color3.fromRGB(255, 0, 150),
            NeonGold = Color3.fromRGB(255, 170, 0), NeonGreen = Color3.fromRGB(46, 204, 113), NeonRed = Color3.fromRGB(231, 76, 60),
            TextWhite = Color3.fromRGB(240, 240, 240)
        }
        
        local AnimationDisplayToKey = {
            ["Parado"] = "Idle", ["Andar"] = "Walk", ["Correr"] = "Run", ["Pular"] = "Jump",
            ["Cair"] = "Fall", ["Nadar"] = "Swim", ["Flutuar"] = "SwimIdle", ["Escalar"] = "Climb"
        }

        local Favoritos = {}
        local MappedIds = {}
        local MappedNames = {}
        local CustomTracks = {}
        local IsRunningAnim = false
        local CurrentCustomState = nil
        local ActiveTrack = nil
        local SistemaAtivado = false
        local ControlsLocked = false

        local ARQUIVO_FAVORITOS = "PainelNeon_AnimFavs.json"
        local ARQUIVO_MAPPINGS = "PainelNeon_Mappings.json"

        local function ApplyCorner(instance, radius)
            local corner = Instance.new("UICorner", instance)
            corner.CornerRadius = UDim.new(0, radius)
        end

        local function ApplyNeonStroke(instance, color, thickness)
            local stroke = Instance.new("UIStroke", instance)
            stroke.Color = color
            stroke.Thickness = thickness or 2
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            return stroke
        end

        local function ApplyPadding(instance, pad)
            local padding = Instance.new("UIPadding", instance)
            padding.PaddingLeft = UDim.new(0, pad)
            padding.PaddingRight = UDim.new(0, pad)
            padding.PaddingTop = UDim.new(0, pad)
            padding.PaddingBottom = UDim.new(0, pad)
        end

        local function LoadFavoritesFromFile()
            if isfile and isfile(ARQUIVO_FAVORITOS) then
                pcall(function()
                    local salvos = HttpService:JSONDecode(readfile(ARQUIVO_FAVORITOS))
                    Favoritos = salvos or {}
                end)
            end
        end

        local function SaveFavs()
            if writefile then pcall(function() writefile(ARQUIVO_FAVORITOS, HttpService:JSONEncode(Favoritos)) end) end
        end

        local function LoadMappingsFromFile()
            if isfile and isfile(ARQUIVO_MAPPINGS) then
                pcall(function()
                    local data = HttpService:JSONDecode(readfile(ARQUIVO_MAPPINGS))
                    if data then MappedIds = data.MappedIds or {}; MappedNames = data.MappedNames or {} end
                end)
            end
        end

        local function SaveMappingsToFile()
            if writefile then
                pcall(function() writefile(ARQUIVO_MAPPINGS, HttpService:JSONEncode({ MappedIds = MappedIds, MappedNames = MappedNames })) end)
            end
        end

        LoadFavoritesFromFile()
        LoadMappingsFromFile()

        local function LoadTrackForState(state, id, animator)
            if not state or not id or not animator then return end

            local success, result = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
            local animObj = nil

            if success and result and result[1] then
                if result[1]:IsA("Animation") then animObj = result[1] else animObj = result[1]:FindFirstChildOfClass("Animation", true) end
            end

            if not animObj then
                animObj = Instance.new("Animation")
                animObj.AnimationId = "rbxassetid://" .. tostring(id)
            end

            if CustomTracks[state] then
                pcall(function() if CustomTracks[state].IsPlaying then CustomTracks[state]:Stop(0.1) end end)
                CustomTracks[state] = nil
            end

            local ok, track = pcall(function() return animator:LoadAnimation(animObj) end)
            if not ok or not track then return end

            track.Priority = Enum.AnimationPriority.Action4

            if state == "Jump" or state == "Fall" then track.Looped = false else track.Looped = true end
            CustomTracks[state] = track
        end

        local function StopActiveTrack()
            if ActiveTrack then pcall(function() ActiveTrack:Stop(0.15) end); ActiveTrack = nil end
            CurrentCustomState = nil
        end

        local function ChangeCharacterAnimation(state, id)
            if not state or not id then return end
            MappedIds[state] = id
            SaveMappingsToFile()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")

            if animator then
                if ActiveTrack and CurrentCustomState == state then StopActiveTrack() end
                LoadTrackForState(state, id, animator)
                CurrentCustomState = nil
            end
        end

        local function ReapplyAnimationsToCharacter(char)
            if not char then return end
            local hum = char:WaitForChild("Humanoid", 5)
            if not hum then return end
            local animator = hum:WaitForChild("Animator", 5)
            if not animator then return end

            for _, track in pairs(CustomTracks) do pcall(function() if track and track.IsPlaying then track:Stop(0.1) end end) end
            CustomTracks = {}

            for state, id in pairs(MappedIds) do pcall(function() LoadTrackForState(state, id, animator) end) end

            if SistemaAtivado then CurrentCustomState = nil
            else if ActiveTrack then pcall(function() ActiveTrack:Stop(0.2) end) ActiveTrack = nil end end
        end

        table.insert(conexoesParaLimpar, player.CharacterAdded:Connect(function(char) task.spawn(function() ReapplyAnimationsToCharacter(char) end) end))
        if player.Character then task.spawn(function() ReapplyAnimationsToCharacter(player.Character) end) end

        local HumStateConn = nil
        local function AttachHumanoidWatcher(hum)
            if not hum then return end
            if HumStateConn then return end 
            
            HumStateConn = hum.StateChanged:Connect(function(oldState, newState)
                if ID_EXECUCAO ~= _G.VersaoAtual then HumStateConn:Disconnect(); return end
                if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics or newState == Enum.HumanoidStateType.Idle then
                    if ActiveTrack and CurrentCustomState == "Fall" then
                        pcall(function() ActiveTrack:Stop(0.15) end)
                        ActiveTrack = nil; CurrentCustomState = nil
                    end
                end
                if newState == Enum.HumanoidStateType.Swimming then
                    if ActiveTrack and (CurrentCustomState == "Jump" or CurrentCustomState == "Fall") then
                        pcall(function() ActiveTrack:Stop(0.15) end)
                        ActiveTrack = nil; CurrentCustomState = nil
                    end
                end
            end)
            table.insert(conexoesParaLimpar, HumStateConn)
        end

        local function PlayTrackForState(state)
            local track = CustomTracks[state]
            if not track then return end

            if ActiveTrack == track and track.IsPlaying then CurrentCustomState = state return end
            if ActiveTrack then pcall(function() ActiveTrack:Stop(0.12) end) ActiveTrack = nil end

            local conn; local ok, _ = pcall(function()
                conn = track.Stopped:Connect(function()
                    if ActiveTrack == track then ActiveTrack = nil; CurrentCustomState = nil end
                    if conn then pcall(function() conn:Disconnect() end); conn = nil end
                end)
            end)

            pcall(function() track:Play(0.1); track:AdjustWeight(1) end)
            ActiveTrack = track; CurrentCustomState = state
        end

        table.insert(conexoesParaLimpar, RunService.RenderStepped:Connect(function()
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")

            if not hum or hum.Health <= 0 or not animator then return end
            AttachHumanoidWatcher(hum)

            if not SistemaAtivado then
                if ActiveTrack then pcall(function() ActiveTrack:Stop(0.15) end); ActiveTrack = nil; CurrentCustomState = nil end
                return
            end

            local state = hum:GetState()
            local moving = hum.MoveDirection.Magnitude > 0
            local desiredState = "Idle"

            if state == Enum.HumanoidStateType.Jumping then desiredState = "Jump"
            elseif state == Enum.HumanoidStateType.Freefall then desiredState = "Fall"
            elseif state == Enum.HumanoidStateType.Climbing then desiredState = "Climb"
            elseif state == Enum.HumanoidStateType.Swimming then desiredState = moving and "Swim" or "SwimIdle"
            else
                if moving then
                    desiredState = IsRunningAnim and "Run" or "Walk"
                    pcall(function() hum.WalkSpeed = IsRunningAnim and 25 or 16 end)
                else
                    desiredState = "Idle"
                end
            end

            if CurrentCustomState == desiredState and ActiveTrack and ActiveTrack.IsPlaying then pcall(function() ActiveTrack:AdjustWeight(1) end) return end

            if desiredState == "Jump" or desiredState == "Fall" or desiredState == "Swim" or desiredState == "SwimIdle" then
                if CustomTracks[desiredState] then PlayTrackForState(desiredState)
                else if ActiveTrack and (CurrentCustomState == "Jump" or CurrentCustomState == "Fall") then pcall(function() ActiveTrack:Stop(0.12) end); ActiveTrack = nil; CurrentCustomState = nil end end
                return
            end

            if CustomTracks[desiredState] then PlayTrackForState(desiredState)
            else if ActiveTrack then pcall(function() ActiveTrack:Stop(0.12) end); ActiveTrack = nil; CurrentCustomState = nil end end
        end))

        local AnimMainFrame = Instance.new("Frame")
        AnimMainFrame.Size = UDim2.new(0, 520, 0, 390)
        AnimMainFrame.Position = UDim2.new(0.5, -260, 0.5, 270)
        AnimMainFrame.BackgroundColor3 = AnimTheme.Background
        AnimMainFrame.BackgroundTransparency = AnimTheme.Transparency
        AnimMainFrame.BorderSizePixel = 0
        AnimMainFrame.Visible = false
        AnimMainFrame.Active = true
        AnimMainFrame.Parent = screenGui
        ApplyCorner(AnimMainFrame, 12)
        ApplyNeonStroke(AnimMainFrame, AnimTheme.NeonCyan, 2)

        local arrastarAnim, animStart, uiAnimStart
        AnimMainFrame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                arrastarAnim = true; animStart = i.Position; uiAnimStart = AnimMainFrame.Position
            end
        end)
        table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(i)
            if arrastarAnim and i.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = i.Position - animStart
                AnimMainFrame.Position = UDim2.new(uiAnimStart.X.Scale, uiAnimStart.X.Offset + delta.X, uiAnimStart.Y.Scale, uiAnimStart.Y.Offset + delta.Y)
            end
        end))
        table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then arrastarAnim = false end
        end))

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -140, 0, 45)
        Title.Position = UDim2.new(0, 0, 0, 0)
        Title.BackgroundTransparency = 1
        Title.TextColor3 = AnimTheme.NeonCyan
        Title.Text = " ⚡ ANIMATION CHANGER"
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 16
        Title.TextXAlignment = Enum.TextXAlignment.Left
        ApplyPadding(Title, 12)
        Title.Parent = AnimMainFrame

        local MasterToggleBtn = Instance.new("TextButton")
        MasterToggleBtn.Size = UDim2.new(0, 90, 0, 30)
        MasterToggleBtn.Position = UDim2.new(1, -135, 0, 7)
        MasterToggleBtn.BackgroundColor3 = AnimTheme.NeonGreen
        MasterToggleBtn.BackgroundTransparency = 0.5
        MasterToggleBtn.TextColor3 = AnimTheme.TextWhite
        MasterToggleBtn.Text = "ATIVADO"
        MasterToggleBtn.Font = Enum.Font.GothamBold
        MasterToggleBtn.TextSize = 12
        MasterToggleBtn.Parent = AnimMainFrame
        ApplyCorner(MasterToggleBtn, 8)
        local MasterStroke = ApplyNeonStroke(MasterToggleBtn, AnimTheme.NeonGreen, 1.5)

        local function ToggleSistema()
            SistemaAtivado = not SistemaAtivado
            if SistemaAtivado then
                MasterToggleBtn.Text = "ATIVADO"
                MasterToggleBtn.BackgroundColor3 = AnimTheme.NeonGreen
                MasterStroke.Color = AnimTheme.NeonGreen
                CurrentCustomState = nil
            else
                MasterToggleBtn.Text = "DESATIVADO"
                MasterToggleBtn.BackgroundColor3 = AnimTheme.NeonRed
                MasterStroke.Color = AnimTheme.NeonRed
                StopActiveTrack()
            end
        end

        table.insert(conexoesParaLimpar, MasterToggleBtn.MouseButton1Click:Connect(function() ToggleSistema() end))

        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 30, 0, 30)
        CloseBtn.Position = UDim2.new(1, -38, 0, 7)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        CloseBtn.BackgroundTransparency = 0.5
        CloseBtn.TextColor3 = AnimTheme.NeonPink
        CloseBtn.Text = "X"
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.TextSize = 14
        CloseBtn.Parent = AnimMainFrame
        ApplyCorner(CloseBtn, 8)
        ApplyNeonStroke(CloseBtn, AnimTheme.NeonPink, 1.5)

        table.insert(conexoesParaLimpar, CloseBtn.MouseButton1Click:Connect(function() AnimMainFrame.Visible = false end))

        local Divider = Instance.new("Frame")
        Divider.Size = UDim2.new(1, 0, 0, 1)
        Divider.Position = UDim2.new(0, 0, 0, 45)
        Divider.BackgroundColor3 = AnimTheme.NeonCyan
        Divider.BackgroundTransparency = 0.5
        Divider.Parent = AnimMainFrame

        local TabContainer = Instance.new("ScrollingFrame")
        TabContainer.Size = UDim2.new(0, 140, 1, -46)
        TabContainer.Position = UDim2.new(0, 0, 0, 46)
        TabContainer.BackgroundTransparency = 1
        TabContainer.BorderSizePixel = 0
        TabContainer.CanvasSize = UDim2.new(0, 0, 1.6, 0)
        TabContainer.ScrollBarThickness = 3
        TabContainer.ScrollBarImageColor3 = AnimTheme.NeonCyan
        TabContainer.Parent = AnimMainFrame
        local UIListLayout = Instance.new("UIListLayout", TabContainer)
        UIListLayout.Padding = UDim.new(0, 5)
        ApplyPadding(TabContainer, 5)

        local VerticalDivider = Instance.new("Frame")
        VerticalDivider.Size = UDim2.new(0, 1, 1, -46)
        VerticalDivider.Position = UDim2.new(0, 140, 0, 46)
        VerticalDivider.BackgroundColor3 = AnimTheme.NeonCyan
        VerticalDivider.BackgroundTransparency = 0.5
        VerticalDivider.Parent = AnimMainFrame

        local ContentFrame = Instance.new("Frame")
        ContentFrame.Size = UDim2.new(1, -145, 1, -46)
        ContentFrame.Position = UDim2.new(0, 145, 0, 46)
        ContentFrame.BackgroundTransparency = 1
        ContentFrame.Parent = AnimMainFrame

        local EditorFrame = Instance.new("Frame")
        EditorFrame.Size = UDim2.new(1, 0, 1, 0)
        EditorFrame.BackgroundTransparency = 1
        EditorFrame.Parent = ContentFrame

        local CurrentStateText = Instance.new("TextLabel")
        CurrentStateText.Size = UDim2.new(1, -20, 0, 40)
        CurrentStateText.Position = UDim2.new(0, 10, 0, 10)
        CurrentStateText.BackgroundTransparency = 1
        CurrentStateText.TextColor3 = AnimTheme.TextWhite
        CurrentStateText.Text = "Selecione uma animação ao lado"
        CurrentStateText.Font = Enum.Font.GothamBold
        CurrentStateText.TextSize = 18
        CurrentStateText.TextXAlignment = Enum.TextXAlignment.Left
        CurrentStateText.Parent = EditorFrame

        local EmoteNameLabel = Instance.new("TextLabel")
        EmoteNameLabel.Size = UDim2.new(1, -20, 0, 25)
        EmoteNameLabel.Position = UDim2.new(0, 10, 0, 50)
        EmoteNameLabel.BackgroundTransparency = 1
        EmoteNameLabel.TextColor3 = AnimTheme.NeonCyan
        EmoteNameLabel.Text = "Nenhum ID inserido"
        EmoteNameLabel.Font = Enum.Font.GothamMedium
        EmoteNameLabel.TextSize = 13
        EmoteNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        EmoteNameLabel.Parent = EditorFrame

        local IdInput = Instance.new("TextBox")
        IdInput.Size = UDim2.new(0.65, -15, 0, 40)
        IdInput.Position = UDim2.new(0, 10, 0, 90)
        IdInput.BackgroundColor3 = AnimTheme.Background
        IdInput.BackgroundTransparency = 0.4
        IdInput.TextColor3 = AnimTheme.TextWhite
        IdInput.PlaceholderText = "Cole o ID do Emote..."
        IdInput.Text = ""
        IdInput.Font = Enum.Font.GothamMedium
        IdInput.TextSize = 14
        IdInput.ClearTextOnFocus = false
        ApplyCorner(IdInput, 8)
        ApplyPadding(IdInput, 10)
        ApplyNeonStroke(IdInput, Color3.fromRGB(100, 100, 100), 1)
        IdInput.Parent = EditorFrame

        local ApplyBtn = Instance.new("TextButton")
        ApplyBtn.Size = UDim2.new(0.35, -15, 0, 40)
        ApplyBtn.Position = UDim2.new(0.65, 5, 0, 90)
        ApplyBtn.BackgroundColor3 = AnimTheme.NeonCyan
        ApplyBtn.BackgroundTransparency = 0.8
        ApplyBtn.TextColor3 = AnimTheme.NeonCyan
        ApplyBtn.Text = "Aplicar"
        ApplyBtn.Font = Enum.Font.GothamBold
        ApplyBtn.TextSize = 14
        ApplyCorner(ApplyBtn, 8)
        ApplyNeonStroke(ApplyBtn, AnimTheme.NeonCyan, 1.5)
        ApplyBtn.Parent = EditorFrame

        local StarBtn = Instance.new("TextButton")
        StarBtn.Size = UDim2.new(1, -20, 0, 40)
        StarBtn.Position = UDim2.new(0, 10, 0, 145)
        StarBtn.BackgroundColor3 = AnimTheme.NeonGold
        StarBtn.BackgroundTransparency = 0.8
        StarBtn.TextColor3 = AnimTheme.NeonGold
        StarBtn.Text = "⭐ Favoritar Emote (Salvar)"
        StarBtn.Font = Enum.Font.GothamBold
        StarBtn.TextSize = 14
        ApplyCorner(StarBtn, 8)
        ApplyNeonStroke(StarBtn, AnimTheme.NeonGold, 1.5)
        StarBtn.Parent = EditorFrame

        local FavoritesFrame = Instance.new("Frame")
        FavoritesFrame.Size = UDim2.new(1, 0, 1, 0)
        FavoritesFrame.BackgroundTransparency = 1
        FavoritesFrame.Visible = false
        FavoritesFrame.Parent = ContentFrame

        local FavTitle = Instance.new("TextLabel")
        FavTitle.Size = UDim2.new(1, -20, 0, 35)
        FavTitle.Position = UDim2.new(0, 10, 0, 10)
        FavTitle.BackgroundTransparency = 1
        FavTitle.TextColor3 = AnimTheme.NeonGold
        FavTitle.Text = "⭐ MEUS EMOTES SALVOS"
        FavTitle.Font = Enum.Font.GothamBold
        FavTitle.TextSize = 16
        FavTitle.TextXAlignment = Enum.TextXAlignment.Left
        FavTitle.Parent = FavoritesFrame

        local FavScroll = Instance.new("ScrollingFrame")
        FavScroll.Size = UDim2.new(1, -20, 1, -60)
        FavScroll.Position = UDim2.new(0, 10, 0, 50)
        FavScroll.BackgroundTransparency = 1
        FavScroll.BorderSizePixel = 0
        FavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        FavScroll.ScrollBarThickness = 4
        FavScroll.ScrollBarImageColor3 = AnimTheme.NeonGold
        FavScroll.Parent = FavoritesFrame

        local FavListLayout = Instance.new("UIListLayout")
        FavListLayout.Parent = FavScroll
        FavListLayout.Padding = UDim.new(0, 6)

        local SelectedState = nil

        local function UpdateFavoritesListUI()
            for _, child in ipairs(FavScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

            for i, fav in ipairs(Favoritos) do
                local Card = Instance.new("Frame")
                Card.Size = UDim2.new(1, -5, 0, 45)
                Card.BackgroundColor3 = AnimTheme.Background
                Card.BackgroundTransparency = 0.5
                Card.Parent = FavScroll
                ApplyCorner(Card, 6)
                ApplyNeonStroke(Card, AnimTheme.NeonGold, 1)

                local InfoLabel = Instance.new("TextLabel")
                InfoLabel.Size = UDim2.new(0.7, 0, 1, 0)
                InfoLabel.BackgroundTransparency = 1
                InfoLabel.TextColor3 = AnimTheme.TextWhite
                InfoLabel.Text = " " .. fav.Name .. "\n (" .. fav.Id .. ")"
                InfoLabel.Font = Enum.Font.GothamMedium
                InfoLabel.TextSize = 11
                InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
                InfoLabel.Parent = Card

                local UseBtn = Instance.new("TextButton")
                UseBtn.Size = UDim2.new(0.18, 0, 0.7, 0)
                UseBtn.Position = UDim2.new(0.7, 0, 0.15, 0)
                UseBtn.BackgroundColor3 = AnimTheme.NeonCyan
                UseBtn.BackgroundTransparency = 0.2
                UseBtn.TextColor3 = Color3.fromRGB(0,0,0)
                UseBtn.Text = "Carregar"
                UseBtn.Font = Enum.Font.GothamBold
                UseBtn.TextSize = 12
                ApplyCorner(UseBtn, 4)
                UseBtn.Parent = Card

                local RemoveBtn = Instance.new("TextButton")
                RemoveBtn.Size = UDim2.new(0.1, 0, 0.7, 0)
                RemoveBtn.Position = UDim2.new(0.88, 0, 0.15, 0)
                RemoveBtn.BackgroundColor3 = AnimTheme.NeonRed
                RemoveBtn.BackgroundTransparency = 0.2
                RemoveBtn.TextColor3 = Color3.fromRGB(0,0,0)
                RemoveBtn.Text = "X"
                RemoveBtn.Font = Enum.Font.GothamBold
                RemoveBtn.TextSize = 12
                ApplyCorner(RemoveBtn, 4)
                RemoveBtn.Parent = Card

                table.insert(conexoesParaLimpar, UseBtn.MouseButton1Click:Connect(function()
                    IdInput.Text = tostring(fav.Id)
                    EmoteNameLabel.Text = "🎵 Emote Selecionado: " .. fav.Name
                    FavoritesFrame.Visible = false
                    EditorFrame.Visible = true
                    if SelectedState then CurrentStateText.Text = "Modificando: " .. SelectedState
                    else CurrentStateText.Text = "Escolha uma Animação na lateral" end
                end))

                table.insert(conexoesParaLimpar, RemoveBtn.MouseButton1Click:Connect(function()
                    if ControlsLocked then
                        RemoveBtn.Text = "🔒"
                        task.delay(1, function() RemoveBtn.Text = "X" end)
                        return
                    end
                    RemoveBtn.Text = "CONFIRM?"
                    local confirmed = false
                    local conn
                    conn = RemoveBtn.MouseButton1Click:Connect(function()
                        confirmed = true
                        conn:Disconnect()
                    end)
                    task.wait(1.2)
                    if confirmed then
                        table.remove(Favoritos, i)
                        SaveFavs()
                        UpdateFavoritesListUI()
                    else
                        RemoveBtn.Text = "X"
                    end
                end))
            end
            FavScroll.CanvasSize = UDim2.new(0, 0, 0, FavListLayout.AbsoluteContentSize.Y + 10)
        end

        local TabButtons = {}

        local function UpdateEditorForSelectedState()
            if not SelectedState then
                IdInput.Text = ""
                EmoteNameLabel.Text = "Nenhum ID inserido"
                return
            end
            local stateKey = AnimationDisplayToKey[SelectedState]
            if stateKey and MappedIds[stateKey] then
                IdInput.Text = tostring(MappedIds[stateKey])
                if MappedNames[stateKey] then EmoteNameLabel.Text = "🎵 Emote atribuído: " .. MappedNames[stateKey]
                else
                    EmoteNameLabel.Text = "🔍 Buscando nome..."
                    task.spawn(function()
                        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(MappedIds[stateKey], Enum.InfoType.Asset) end)
                        if ok and info and info.Name then
                            MappedNames[stateKey] = info.Name
                            EmoteNameLabel.Text = "🎵 Emote atribuído: " .. info.Name
                            SaveMappingsToFile()
                        else
                            EmoteNameLabel.Text = "🎵 Emote atribuído: ID " .. tostring(MappedIds[stateKey])
                        end
                    end)
                end
            else
                IdInput.Text = ""
                EmoteNameLabel.Text = "Nenhum ID inserido"
            end
        end

        for displayName, stateKey in pairs(AnimationDisplayToKey) do
            local TabBtn = Instance.new("TextButton")
            TabBtn.Size = UDim2.new(1, -10, 0, 35)
            TabBtn.BackgroundColor3 = AnimTheme.Background
            TabBtn.BackgroundTransparency = 0.6
            TabBtn.TextColor3 = Color3.fromRGB(160, 160, 160)
            TabBtn.Text = displayName
            TabBtn.Font = Enum.Font.GothamMedium
            TabBtn.TextSize = 13
            ApplyCorner(TabBtn, 6)
            local stroke = ApplyNeonStroke(TabBtn, AnimTheme.NeonCyan, 0)
            TabBtn.Parent = TabContainer

            table.insert(TabButtons, {Btn = TabBtn, Stroke = stroke, IsFavTab = false, StateKey = stateKey, DisplayName = displayName})

            table.insert(conexoesParaLimpar, TabBtn.MouseButton1Click:Connect(function()
                SelectedState = displayName
                FavoritesFrame.Visible = false
                EditorFrame.Visible = true
                CurrentStateText.Text = "Modificando: " .. displayName

                for _, data in ipairs(TabButtons) do
                    data.Btn.TextColor3 = Color3.fromRGB(160, 160, 160)
                    data.Stroke.Color = AnimTheme.NeonCyan
                    data.Stroke.Thickness = 0
                end
                TabBtn.TextColor3 = AnimTheme.NeonCyan
                stroke.Thickness = 1.5
                UpdateEditorForSelectedState()
            end))
        end

        local FavTabBtn = Instance.new("TextButton")
        FavTabBtn.Size = UDim2.new(1, -10, 0, 35)
        FavTabBtn.BackgroundColor3 = AnimTheme.Background
        FavTabBtn.BackgroundTransparency = 0.6
        FavTabBtn.TextColor3 = AnimTheme.NeonGold
        FavTabBtn.Text = "⭐ Favoritos"
        FavTabBtn.Font = Enum.Font.GothamBold
        FavTabBtn.TextSize = 13
        ApplyCorner(FavTabBtn, 6)
        local FavTabStroke = ApplyNeonStroke(FavTabBtn, AnimTheme.NeonGold, 0)
        FavTabBtn.Parent = TabContainer

        table.insert(TabButtons, {Btn = FavTabBtn, Stroke = FavTabStroke, IsFavTab = true})

        table.insert(conexoesParaLimpar, FavTabBtn.MouseButton1Click:Connect(function()
            EditorFrame.Visible = false
            FavoritesFrame.Visible = true
            UpdateFavoritesListUI()

            for _, data in ipairs(TabButtons) do
                data.Btn.TextColor3 = data.IsFavTab and AnimTheme.NeonGold or Color3.fromRGB(160, 160, 160)
                data.Stroke.Thickness = 0
            end
            FavTabStroke.Thickness = 1.5
        end))

        local function ToggleControlsLock()
            ControlsLocked = not ControlsLocked
            if ControlsLocked then CurrentStateText.Text = "🔒 Controles Bloqueados"
            else
                CurrentStateText.Text = "🔓 Controles Liberados"
                task.delay(1.2, function() CurrentStateText.Text = SelectedState and ("Modificando: " .. SelectedState) or "Selecione uma animação ao lado" end)
            end
        end

        local function ToggleRunState()
            IsRunningAnim = not IsRunningAnim
            StopActiveTrack()

            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.WalkSpeed = IsRunningAnim and 25 or 16 end) end

            CurrentStateText.Text = IsRunningAnim and "🏃 Correndo" or "🚶 Andando"
            task.delay(1.2, function()
                CurrentStateText.Text = SelectedState and ("Modificando: " .. SelectedState) or "Selecione uma animação ao lado"
            end)
        end

        -- COMANDOS DE TECLADO MANTIDOS COMPLETAMENTE IGUAIS
        local COMBO_WINDOW = 0.03
        local CtrlHeld = false
        local CtrlUsedForCombo = false
        local ctrlTimer = nil

        local function CancelCtrlTimer()
            ctrlTimer = nil
        end

        table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gpe)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if IdInput and IdInput:IsFocused() then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local key = input.KeyCode

            if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then
                CtrlHeld = true
                CtrlUsedForCombo = false
                ctrlTimer = task.spawn(function()
                    task.wait(COMBO_WINDOW)
                    if CtrlHeld and not CtrlUsedForCombo then ToggleRunState() end
                    ctrlTimer = nil
                end)
                return
            end

            if CtrlHeld then
                if key == Enum.KeyCode.O then
                    CtrlUsedForCombo = true
                    CancelCtrlTimer()
                    AnimMainFrame.Visible = not AnimMainFrame.Visible
                    btnANIM.BackgroundColor3 = AnimMainFrame.Visible and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
                    btnANIM.TextColor3 = AnimMainFrame.Visible and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
                    return
                end

                if key == Enum.KeyCode.L then
                    CtrlUsedForCombo = true
                    CancelCtrlTimer()
                    ToggleControlsLock()
                    return
                end

                if key == Enum.KeyCode.I then
                    CtrlUsedForCombo = true
                    CancelCtrlTimer()
                    ToggleSistema()
                    return
                end
            end
        end))

        table.insert(conexoesParaLimpar, UserInputService.InputEnded:Connect(function(input, gpe)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local key = input.KeyCode
            if key == Enum.KeyCode.LeftControl or key == Enum.KeyCode.RightControl then
                CtrlHeld = false
                CtrlUsedForCombo = false
                CancelCtrlTimer()
            end
        end))

        table.insert(conexoesParaLimpar, IdInput.FocusLost:Connect(function()
            local id = tonumber(IdInput.Text)
            if id then
                EmoteNameLabel.Text = "🔍 Buscando informações..."
                task.spawn(function()
                    local success, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
                    if success and info and info.Name then EmoteNameLabel.Text = "🎵 Emote: " .. info.Name
                    else EmoteNameLabel.Text = "❌ ID Válido, mas sem nome público." end
                end)
            else EmoteNameLabel.Text = "❌ Digite apenas números (ID)." end
        end))

        table.insert(conexoesParaLimpar, ApplyBtn.MouseButton1Click:Connect(function()
            if ControlsLocked then
                CurrentStateText.Text = "🔒 Edição bloqueada"
                task.delay(1.2, function() CurrentStateText.Text = SelectedState and ("Modificando: " .. SelectedState) or "Selecione uma animação ao lado" end)
                return
            end

            local id = tonumber(IdInput.Text)
            if SelectedState and id then
                local stateKey = AnimationDisplayToKey[SelectedState]
                if not stateKey then
                    CurrentStateText.Text = "⚠️ Estado inválido"
                    task.delay(1.2, function() CurrentStateText.Text = SelectedState and ("Modificando: " .. SelectedState) or "Selecione uma animação ao lado" end)
                    return
                end

                MappedIds[stateKey] = id
                SaveMappingsToFile()

                EmoteNameLabel.Text = "🔍 Buscando nome..."
                task.spawn(function()
                    local success, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
                    if success and info and info.Name then
                        MappedNames[stateKey] = info.Name
                        EmoteNameLabel.Text = "🎵 Emote atribuído: " .. info.Name
                    else
                        MappedNames[stateKey] = "Emote " .. tostring(id)
                        EmoteNameLabel.Text = "🎵 Emote atribuído: " .. MappedNames[stateKey]
                    end
                    SaveMappingsToFile()
                end)

                ChangeCharacterAnimation(stateKey, id)
                CurrentStateText.Text = "✅ APLICADO COM SUCESSO!"
                task.wait(1.5)
                CurrentStateText.Text = "Modificando: " .. SelectedState
            else
                CurrentStateText.Text = "⚠️ Escolha a animação e digite o ID!"
            end
        end))

        table.insert(conexoesParaLimpar, StarBtn.MouseButton1Click:Connect(function()
            if ControlsLocked then
                StarBtn.Text = "🔒"
                task.delay(1, function() StarBtn.Text = "⭐ Favoritar Emote (Salvar)" end)
                return
            end

            local id = tonumber(IdInput.Text)
            if id then
                StarBtn.Text = "🔍 Buscando Nome..."
                task.spawn(function()
                    local name = nil
                    local success, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Asset) end)
                    if success and info and info.Name then name = info.Name else name = "Emote " .. id end

                    local exists = false
                    for _, item in ipairs(Favoritos) do
                        if item.Id == id then exists = true break end
                    end
                    if not exists then
                        table.insert(Favoritos, {Id = id, Name = name})
                        SaveFavs()
                    end
                    StarBtn.Text = "⭐ SALVO NA SUA ABA!"
                    task.wait(1.5)
                    StarBtn.Text = "⭐ Favoritar Emote (Salvar)"
                end)
            end
        end))

        local AnimPainelVisivel = false
        table.insert(conexoesParaLimpar, btnANIM.MouseButton1Click:Connect(function()
            AnimPainelVisivel = not AnimPainelVisivel
            AnimMainFrame.Visible = AnimPainelVisivel
            btnANIM.BackgroundColor3 = AnimPainelVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnANIM.TextColor3 = AnimPainelVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        end))

    end
    -- [FIM DA ADIÇÃO: ANIMATION CHANGER UNIFICADO]

    -- [INÍCIO DA ADIÇÃO: LOCALIZADOR ESP]
    local btnLOCALIZAR = criarBotaoMenu("LOCALIZAR", 210, Color3.fromRGB(0, 255, 255))
    btnLOCALIZAR.Position = UDim2.new(0, -88, 0, 210)

    do
        local LocalPlayer = player -- Adaptação limpa para manter o script do localizador

        -- [[ CONFIGURAÇÃO DO TEMA NEON ]] --
        local TEMA = {
            BgPrincipal = Color3.fromRGB(11, 11, 14),
            BgSecundario = Color3.fromRGB(18, 18, 24),
            NeonCiano = Color3.fromRGB(0, 255, 255),
            NeonVerde = Color3.fromRGB(50, 255, 50),
            NeonRosa = Color3.fromRGB(255, 0, 127),
            TextoBranco = Color3.fromRGB(255, 255, 255),
            Transparencia = 0.15
        }

        -- [[ VARIÁVEIS DE ESTADO ]] --
        local alvoAtual = nil
        local espGeralAtivo = false
        local espAlvoAtivo = false

        -- [[ FUNÇÕES DE VISUALIZAÇÃO (AURA, PILAR E FUMAÇA) ]] --
        local function aplicarAura(personagem, cor, nomeAura)
            if not personagem then return end

            if personagem:FindFirstChild(nomeAura) then
                personagem[nomeAura]:Destroy()
            end

            local aura = Instance.new("Highlight")
            aura.Name = nomeAura
            aura.FillColor = cor
            aura.OutlineColor = Color3.fromRGB(255, 255, 255)
            aura.FillTransparency = 0.5
            aura.OutlineTransparency = 0.1
            aura.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            aura.Parent = personagem

            local hrp = personagem:FindFirstChild("HumanoidRootPart")
            if hrp then
                local adornName = nomeAura .. "_Adorn"
                if hrp:FindFirstChild(adornName) then
                    hrp[adornName]:Destroy()
                end

                local adorn = Instance.new("BoxHandleAdornment")
                adorn.Name = adornName
                adorn.Size = Vector3.new(2.5, 5.5, 2.5)
                adorn.Color3 = cor
                adorn.Transparency = 0.35
                adorn.AlwaysOnTop = true
                adorn.ZIndex = 0
                adorn.Adornee = hrp
                adorn.CFrame = hrp.CFrame * CFrame.new(0, 2.75, 0)
                adorn.Parent = hrp

                local nameGuiName = nomeAura .. "_Name"
                if hrp:FindFirstChild(nameGuiName) then
                    hrp[nameGuiName]:Destroy()
                end

                local playerObj = Players:GetPlayerFromCharacter(personagem)
                local displayText = playerObj and playerObj.DisplayName or personagem.Name

                local billboard = Instance.new("BillboardGui")
                billboard.Name = nameGuiName
                billboard.Adornee = hrp
                billboard.Size = UDim2.new(0, 180, 0, 24)
                billboard.StudsOffset = Vector3.new(0, 4.5, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = hrp

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1       
                label.BorderSizePixel = 0
                label.Text = string.upper(displayText)
                label.TextColor3 = cor
                label.Font = Enum.Font.GothamBold
                label.TextSize = 10                     
                label.TextStrokeTransparency = 0.8      
                label.TextTransparency = 0
                label.Parent = billboard
            end
        end

        local function aplicarFumacaVertical(personagem, cor)
            task.spawn(function()
                local hrp = personagem:WaitForChild("HumanoidRootPart", 5)
                if not hrp then return end

                if hrp:FindFirstChild("FumacaEspiao") then hrp.FumacaEspiao:Destroy() end
                if hrp:FindFirstChild("PilarEspiao") then hrp.PilarEspiao:Destroy() end

                local attach = Instance.new("Attachment")
                attach.Name = "FumacaEspiao"
                attach.Position = Vector3.new(0, -2, 0)
                attach.Parent = hrp

                local emit = Instance.new("ParticleEmitter")
                emit.Texture = "rbxasset://textures/particles/smoke_main.dds" 
                emit.Color = ColorSequence.new(cor)
                emit.LightEmission = 1 
                emit.LightInfluence = 0
                emit.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 4), 
                    NumberSequenceKeypoint.new(1, 30)
                })
                emit.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.1), 
                    NumberSequenceKeypoint.new(0.8, 0.2),
                    NumberSequenceKeypoint.new(1, 1) 
                })
                emit.Speed = NumberRange.new(120, 180)
                emit.Lifetime = NumberRange.new(15, 20)
                emit.EmissionDirection = Enum.NormalId.Top
                emit.Rate = 80
                emit.Rotation = NumberRange.new(0, 360)
                emit.RotSpeed = NumberRange.new(-30, 30)
                emit.ZOffset = 500
                emit.Parent = attach

                local pilar = Instance.new("BoxHandleAdornment")
                pilar.Name = "PilarEspiao"
                pilar.Size = Vector3.new(1.5, 2000, 1.5)
                pilar.Color3 = cor
                pilar.Transparency = 0.5
                pilar.AlwaysOnTop = true
                pilar.ZIndex = 0
                pilar.Adornee = hrp
                pilar.CFrame = CFrame.new(0, 1000, 0)
                pilar.Parent = hrp
            end)
        end

        local function limparEfeitos(personagem, nomeAura)
            if not personagem then return end

            if personagem:FindFirstChild(nomeAura) then
                personagem[nomeAura]:Destroy()
            end

            local hrp = personagem:FindFirstChild("HumanoidRootPart")
            if hrp then
                local adornName = nomeAura .. "_Adorn"
                if hrp:FindFirstChild(adornName) then
                    hrp[adornName]:Destroy()
                end

                local nameGuiName = nomeAura .. "_Name"
                if hrp:FindFirstChild(nameGuiName) then
                    hrp[nameGuiName]:Destroy()
                end

                if nomeAura == "AuraAlvo" then
                    if hrp:FindFirstChild("FumacaEspiao") then hrp.FumacaEspiao:Destroy() end
                    if hrp:FindFirstChild("PilarEspiao") then hrp.PilarEspiao:Destroy() end
                end
            end
        end

        -- [[ CRIAÇÃO DA INTERFACE DO LOCALIZADOR ]] --
        local LocalizadorMainFrame = Instance.new("Frame")
        LocalizadorMainFrame.Size = UDim2.new(0, 290, 0, 370)
        LocalizadorMainFrame.Position = UDim2.new(0.5, 150, 0.3, 0)
        LocalizadorMainFrame.BackgroundColor3 = TEMA.BgPrincipal
        LocalizadorMainFrame.BackgroundTransparency = TEMA.Transparencia
        LocalizadorMainFrame.BorderSizePixel = 0
        LocalizadorMainFrame.Active = true
        LocalizadorMainFrame.Visible = false -- Inicia oculto conforme solicitado
        LocalizadorMainFrame.ClipsDescendants = true 
        LocalizadorMainFrame.Parent = screenGui -- Acoplado ao ScreenGui mestre

        local LocUICorner = Instance.new("UICorner")
        LocUICorner.CornerRadius = UDim.new(0, 12)
        LocUICorner.Parent = LocalizadorMainFrame

        local LocUIStroke = Instance.new("UIStroke")
        LocUIStroke.Color = TEMA.NeonVerde
        LocUIStroke.Thickness = 1.5
        LocUIStroke.Parent = LocalizadorMainFrame

        local LocTitleLabel = Instance.new("TextLabel")
        LocTitleLabel.Size = UDim2.new(1, 0, 0, 38)
        LocTitleLabel.BackgroundColor3 = TEMA.BgSecundario
        LocTitleLabel.BackgroundTransparency = 0.1
        LocTitleLabel.Text = "LOCALIZAR"
        LocTitleLabel.TextColor3 = TEMA.NeonVerde
        LocTitleLabel.Font = Enum.Font.GothamBold
        LocTitleLabel.TextSize = 10
        LocTitleLabel.TextXAlignment = Enum.TextXAlignment.Center
        LocTitleLabel.BorderSizePixel = 0
        LocTitleLabel.Parent = LocalizadorMainFrame

        local LocTitleCorner = Instance.new("UICorner")
        LocTitleCorner.CornerRadius = UDim.new(0, 12)
        LocTitleCorner.Parent = LocTitleLabel

        local LocTitleStroke = Instance.new("UIStroke")
        LocTitleStroke.Color = TEMA.NeonVerde
        LocTitleStroke.Parent = LocTitleLabel

        local LocGeralButton = Instance.new("TextButton")
        LocGeralButton.Size = UDim2.new(0.9, 0, 0, 35)
        LocGeralButton.Position = UDim2.new(0.05, 0, 0, 45)
        LocGeralButton.BackgroundColor3 = TEMA.BgSecundario
        LocGeralButton.Text = "GERAL: OFF"
        LocGeralButton.TextColor3 = TEMA.NeonVerde
        LocGeralButton.Font = Enum.Font.GothamBold
        LocGeralButton.TextSize = 10
        LocGeralButton.BorderSizePixel = 0
        LocGeralButton.Parent = LocalizadorMainFrame

        local LocGeralCorner = Instance.new("UICorner")
        LocGeralCorner.CornerRadius = UDim.new(0, 6)
        LocGeralCorner.Parent = LocGeralButton

        local LocGeralStroke = Instance.new("UIStroke")
        LocGeralStroke.Color = TEMA.NeonVerde
        LocGeralStroke.Thickness = 1
        LocGeralStroke.Parent = LocGeralButton

        local LocSearchBox = Instance.new("TextBox")
        LocSearchBox.Size = UDim2.new(0.9, 0, 0, 35)
        LocSearchBox.Position = UDim2.new(0.05, 0, 0, 88)
        LocSearchBox.BackgroundColor3 = TEMA.BgSecundario
        LocSearchBox.PlaceholderText = "Pesquisar Jogador..."
        LocSearchBox.Text = ""
        LocSearchBox.TextColor3 = TEMA.TextoBranco
        LocSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 140, 140)
        LocSearchBox.Font = Enum.Font.GothamMedium
        LocSearchBox.TextSize = 10
        LocSearchBox.TextXAlignment = Enum.TextXAlignment.Left
        LocSearchBox.BorderSizePixel = 0
        LocSearchBox.Parent = LocalizadorMainFrame

        local LocSearchCorner = Instance.new("UICorner")
        LocSearchCorner.CornerRadius = UDim.new(0, 6)
        LocSearchCorner.Parent = LocSearchBox

        local LocSearchStroke = Instance.new("UIStroke")
        LocSearchStroke.Color = Color3.fromRGB(60, 60, 75)
        LocSearchStroke.Parent = LocSearchBox

        local LocSearchPadding = Instance.new("UIPadding")
        LocSearchPadding.PaddingLeft = UDim.new(0, 10)
        LocSearchPadding.Parent = LocSearchBox

        local LocSuggestionsFrame = Instance.new("ScrollingFrame")
        LocSuggestionsFrame.Size = UDim2.new(0.9, 0, 0, 185)
        LocSuggestionsFrame.Position = UDim2.new(0.05, 0, 0, 130)
        LocSuggestionsFrame.BackgroundTransparency = 1
        LocSuggestionsFrame.BorderSizePixel = 0
        LocSuggestionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        LocSuggestionsFrame.ScrollBarThickness = 4
        LocSuggestionsFrame.ScrollBarImageColor3 = TEMA.NeonVerde
        LocSuggestionsFrame.Parent = LocalizadorMainFrame

        local LocListLayout = Instance.new("UIListLayout")
        LocListLayout.Padding = UDim.new(0, 6)
        LocListLayout.Parent = LocSuggestionsFrame

        local LocTargetInfoLabel = Instance.new("TextLabel")
        LocTargetInfoLabel.Size = UDim2.new(0.9, 0, 0, 35)
        LocTargetInfoLabel.Position = UDim2.new(0.05, 0, 0, 325)
        LocTargetInfoLabel.BackgroundColor3 = TEMA.BgSecundario
        LocTargetInfoLabel.Text = "ALVO: NENHUM (CTRL X)"
        LocTargetInfoLabel.TextColor3 = TEMA.NeonRosa
        LocTargetInfoLabel.Font = Enum.Font.GothamBold
        LocTargetInfoLabel.TextSize = 10
        LocTargetInfoLabel.BorderSizePixel = 0
        LocTargetInfoLabel.Parent = LocalizadorMainFrame

        local LocTargetCorner = Instance.new("UICorner")
        LocTargetCorner.CornerRadius = UDim.new(0, 6)
        LocTargetCorner.Parent = LocTargetInfoLabel

        local LocTargetStroke = Instance.new("UIStroke")
        LocTargetStroke.Color = TEMA.NeonRosa
        LocTargetStroke.Thickness = 1.5
        LocTargetStroke.Parent = LocTargetInfoLabel

        -- [[ LÓGICA DO ARRASTAR DO LOCALIZADOR ]] --
        local draggingLoc, dragInputLoc, dragStartLoc, startPosLoc

        LocalizadorMainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingLoc = true
                dragStartLoc = input.Position
                startPosLoc = LocalizadorMainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then draggingLoc = false end
                end)
            end
        end)

        LocalizadorMainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInputLoc = input
            end
        end)

        table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(input)
            if input == dragInputLoc and draggingLoc then
                local delta = input.Position - dragStartLoc
                LocalizadorMainFrame.Position = UDim2.new(startPosLoc.X.Scale, startPosLoc.X.Offset + delta.X, startPosLoc.Y.Scale, startPosLoc.Y.Offset + delta.Y)
            end
        end))

        -- [[ CONTROLES DA GERAL ]] --
        local function toggleGeral()
            espGeralAtivo = not espGeralAtivo
            if espGeralAtivo then
                LocGeralButton.Text = "GERAL: ON (CTRL Z)"
                LocGeralStroke.Color = Color3.fromRGB(255, 255, 255)
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        aplicarAura(p.Character, TEMA.NeonVerde, "AuraGeral")
                    end
                end
            else
                LocGeralButton.Text = "GERAL: OFF (CTRL Z)"
                LocGeralStroke.Color = TEMA.NeonVerde
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then limparEfeitos(p.Character, "AuraGeral") end
                end
            end
        end

        table.insert(conexoesParaLimpar, LocGeralButton.MouseButton1Click:Connect(toggleGeral))

        -- [[ CONTROLES DO ALVO ESPECÍFICO ]] --
        local function selecionarAlvo(playerParam)
            if playerParam == LocalPlayer then return end

            if alvoAtual and alvoAtual.Character then
                limparEfeitos(alvoAtual.Character, "AuraAlvo")
            end

            alvoAtual = playerParam
            espAlvoAtivo = true 

            LocTargetInfoLabel.Text = "ALVO: " .. string.upper(playerParam.DisplayName) .. " (ON)"
            LocTargetStroke.Color = Color3.fromRGB(255, 255, 255)

            if alvoAtual.Character then
                aplicarAura(alvoAtual.Character, TEMA.NeonRosa, "AuraAlvo")
                aplicarFumacaVertical(alvoAtual.Character, TEMA.NeonRosa)
            end
        end

        local function toggleAlvo()
            if not alvoAtual then return end

            espAlvoAtivo = not espAlvoAtivo
            if espAlvoAtivo then
                LocTargetInfoLabel.Text = "ALVO: " .. string.upper(alvoAtual.DisplayName) .. " (ON)"
                LocTargetStroke.Color = Color3.fromRGB(255, 255, 255)
                if alvoAtual.Character then
                    aplicarAura(alvoAtual.Character, TEMA.NeonRosa, "AuraAlvo")
                    aplicarFumacaVertical(alvoAtual.Character, TEMA.NeonRosa)
                end
            else
                LocTargetInfoLabel.Text = "ALVO: " .. string.upper(alvoAtual.DisplayName) .. " (OFF)"
                LocTargetStroke.Color = TEMA.NeonRosa
                if alvoAtual.Character then
                    limparEfeitos(alvoAtual.Character, "AuraAlvo")
                end
            end
        end

        -- [[ SISTEMA DE BUSCA FLUIDA ]] --
        local function atualizarListaEsp()
            for _, child in pairs(LocSuggestionsFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local textoBusca = string.lower(LocSearchBox.Text)
            local count = 0

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local nomeValido = string.find(string.lower(p.Name), textoBusca)
                    local displayValido = string.find(string.lower(p.DisplayName), textoBusca)

                    if textoBusca == "" or nomeValido or displayValido then
                        count = count + 1

                        local BotaoPlayer = Instance.new("TextButton")
                        BotaoPlayer.Size = UDim2.new(1, -8, 0, 32)
                        BotaoPlayer.BackgroundColor3 = TEMA.BgSecundario
                        BotaoPlayer.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                        BotaoPlayer.TextColor3 = TEMA.TextoBranco
                        BotaoPlayer.Font = Enum.Font.GothamMedium
                        BotaoPlayer.TextSize = 10
                        BotaoPlayer.TextXAlignment = Enum.TextXAlignment.Left
                        BotaoPlayer.BorderSizePixel = 0
                        BotaoPlayer.Parent = LocSuggestionsFrame

                        local ButtonCorner = Instance.new("UICorner")
                        ButtonCorner.CornerRadius = UDim.new(0, 5)
                        ButtonCorner.Parent = BotaoPlayer

                        local BtnStroke = Instance.new("UIStroke")
                        BtnStroke.Color = Color3.fromRGB(45, 45, 55)
                        BtnStroke.Parent = BotaoPlayer

                        local BtnPadding = Instance.new("UIPadding")
                        BtnPadding.PaddingLeft = UDim.new(0, 10)
                        BtnPadding.Parent = BotaoPlayer

                        BotaoPlayer.MouseEnter:Connect(function()
                            BtnStroke.Color = TEMA.NeonRosa
                            BotaoPlayer.TextColor3 = TEMA.NeonRosa
                        end)
                        BotaoPlayer.MouseLeave:Connect(function()
                            BtnStroke.Color = Color3.fromRGB(45, 45, 55)
                            BotaoPlayer.TextColor3 = TEMA.TextoBranco
                        end)

                        table.insert(conexoesParaLimpar, BotaoPlayer.MouseButton1Click:Connect(function()
                            selecionarAlvo(p)
                        end))
                    end
                end
            end
            LocSuggestionsFrame.CanvasSize = UDim2.new(0, 0, 0, count * 38)
        end

        table.insert(conexoesParaLimpar, LocSearchBox:GetPropertyChangedSignal("Text"):Connect(atualizarListaEsp))
        table.insert(conexoesParaLimpar, Players.PlayerAdded:Connect(atualizarListaEsp))
        table.insert(conexoesParaLimpar, Players.PlayerRemoving:Connect(atualizarListaEsp))
        atualizarListaEsp()

        -- [[ MONITORAMENTO CONTÍNUO (RE-APLICAÇÃO EM RESPAWN) ]] --
        table.insert(conexoesParaLimpar, Players.PlayerAdded:Connect(function(p)
            table.insert(conexoesParaLimpar, p.CharacterAdded:Connect(function(char)
                task.wait(0.5) 
                if espGeralAtivo and p ~= LocalPlayer then
                    aplicarAura(char, TEMA.NeonVerde, "AuraGeral")
                end
                if espAlvoAtivo and p == alvoAtual then
                    aplicarAura(char, TEMA.NeonRosa, "AuraAlvo")
                    aplicarFumacaVertical(char, TEMA.NeonRosa)
                end
            end))
        end))

        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                table.insert(conexoesParaLimpar, p.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    if espGeralAtivo and p ~= LocalPlayer then
                        aplicarAura(char, TEMA.NeonVerde, "AuraGeral")
                    end
                    if espAlvoAtivo and p == alvoAtual then
                        aplicarAura(char, TEMA.NeonRosa, "AuraAlvo")
                        aplicarFumacaVertical(char, TEMA.NeonRosa)
                    end
                end))
            end
        end

        -- [[ ATALHOS DE TECLADO (CTRL + Z / CTRL + X) ]] --
        table.insert(conexoesParaLimpar, UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end

            local ctrlPressionado = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

            if ctrlPressionado then
                if input.KeyCode == Enum.KeyCode.Z then
                    toggleGeral()
                elseif input.KeyCode == Enum.KeyCode.X then
                    toggleAlvo()
                end
            end
        end))

        -- [[ LÓGICA DO BOTÃO MESTRE PARA ABRIR/FECHAR O LOCALIZADOR ]] --
        local LocalizadorVisivel = false
        table.insert(conexoesParaLimpar, btnLOCALIZAR.MouseButton1Click:Connect(function()
            LocalizadorVisivel = not LocalizadorVisivel
            LocalizadorMainFrame.Visible = LocalizadorVisivel
            btnLOCALIZAR.BackgroundColor3 = LocalizadorVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnLOCALIZAR.TextColor3 = LocalizadorVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        end))

    end
    -- [FIM DA ADIÇÃO: LOCALIZADOR ESP]

    -- [INÍCIO DA ADIÇÃO: SISTEMA ESPIÃO]
    local btnESPIAO = criarBotaoMenu("ESPIÃO", 265, Color3.fromRGB(0, 255, 255))
    btnESPIAO.Position = UDim2.new(0, -88, 0, 265)

    do
        -- Tema
        local TEMA = {
            BgPrincipal = Color3.fromRGB(11, 11, 14),
            BgSecundario = Color3.fromRGB(18, 18, 24),
            NeonCiano = Color3.fromRGB(0, 255, 255),
            NeonRosa = Color3.fromRGB(255, 0, 127),
            TextoBranco = Color3.fromRGB(255, 255, 255),
            Transparencia = 0.15
        }

        -- Estado
        local alvoAtual = nil
        local ultimoAlvo = nil
        local filteredPlayers = {}
        local currentIndex = 0
        local isMinimized = false
        local userPaused = true

        -- VARIÁVEL DE CONTROLE DE OTIMIZAÇÃO DA CÂMERA
        local loopCameraEspiao = nil
        local pararEspionagem -- Declaração prévia para poder usar na função abaixo

        -- Suprime restauração automática da câmera para o jogador local enquanto espionando
        local suppressLocalCameraRestore = false

        -- Helpers seguros para câmera
        local function safeSetCameraType(camType)
            if not camera then return end
            pcall(function() camera.CameraType = camType end)
        end

        local function safeSetCameraSubject(subject)
            if not camera then return end
            pcall(function() camera.CameraSubject = subject end)
        end

        local function applyScriptableCameraToHead(head, offset)
            if not head or not camera then return end
            offset = offset or Vector3.new(0, 2, 6)
            local camPos = head.Position + offset
            pcall(function() camera.CFrame = CFrame.new(camPos, head.Position) end)
        end

        local function isPlayerValid(p)
            return p and p.Parent == Players
        end

        local function findNextValidIndex(startIndex, step)
            if #filteredPlayers == 0 then return 0 end
            local n = #filteredPlayers
            local idx = startIndex
            for i = 1, n do
                idx = ((idx - 1 + step) % n) + 1
                local p = filteredPlayers[idx]
                if isPlayerValid(p) then return idx end
            end
            return 0
        end

        -- GUI do Espião
        local EspiaoMainFrame = Instance.new("Frame", screenGui)
        EspiaoMainFrame.Size = UDim2.new(0, 320, 0, 420)
        EspiaoMainFrame.Position = UDim2.new(0.5, 180, 0.25, 0)
        EspiaoMainFrame.BackgroundColor3 = TEMA.BgPrincipal
        EspiaoMainFrame.BackgroundTransparency = TEMA.Transparencia
        EspiaoMainFrame.BorderSizePixel = 0
        EspiaoMainFrame.Active = true
        EspiaoMainFrame.Visible = false

        Instance.new("UICorner", EspiaoMainFrame).CornerRadius = UDim.new(0, 12)
        local UIStroke = Instance.new("UIStroke", EspiaoMainFrame)
        UIStroke.Color = TEMA.NeonCiano
        UIStroke.Thickness = 1.5

        local TitleLabel = Instance.new("TextLabel", EspiaoMainFrame)
        TitleLabel.Size = UDim2.new(1, 0, 0, 42)
        TitleLabel.Position = UDim2.new(0, 0, 0, 0)
        TitleLabel.BackgroundColor3 = TEMA.BgSecundario
        TitleLabel.BackgroundTransparency = 0.1
        TitleLabel.Text = "👁️ SENSOR ESPIÃO"
        TitleLabel.TextColor3 = TEMA.NeonCiano
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 12
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
        TitleLabel.BorderSizePixel = 0
        Instance.new("UICorner", TitleLabel).CornerRadius = UDim.new(0, 12)
        Instance.new("UIStroke", TitleLabel).Color = TEMA.NeonCiano

        local MinimizeButton = Instance.new("TextButton", TitleLabel)
        MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
        MinimizeButton.Position = UDim2.new(1, -38, 0, 6)
        MinimizeButton.BackgroundColor3 = TEMA.BgSecundario
        MinimizeButton.Text = "—"
        MinimizeButton.TextColor3 = TEMA.TextoBranco
        MinimizeButton.Font = Enum.Font.GothamBold
        MinimizeButton.TextSize = 16
        MinimizeButton.BorderSizePixel = 0
        Instance.new("UICorner", MinimizeButton).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", MinimizeButton).Color = TEMA.NeonCiano

        local SearchBox = Instance.new("TextBox", EspiaoMainFrame)
        SearchBox.Size = UDim2.new(0.92, 0, 0, 36)
        SearchBox.Position = UDim2.new(0.04, 0, 0, 54)
        SearchBox.BackgroundColor3 = TEMA.BgSecundario
        SearchBox.PlaceholderText = "Pesquisar Jogador..."
        SearchBox.Text = ""
        SearchBox.TextColor3 = TEMA.TextoBranco
        SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 140, 140)
        SearchBox.Font = Enum.Font.GothamMedium
        SearchBox.TextSize = 12
        SearchBox.TextXAlignment = Enum.TextXAlignment.Left
        SearchBox.BorderSizePixel = 0
        Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", SearchBox).Color = Color3.fromRGB(60, 60, 75)
        local SearchPadding = Instance.new("UIPadding", SearchBox)
        SearchPadding.PaddingLeft = UDim.new(0, 12)

        local SuggestionsFrame = Instance.new("ScrollingFrame", EspiaoMainFrame)
        SuggestionsFrame.Size = UDim2.new(0.92, 0, 0, 200)
        SuggestionsFrame.Position = UDim2.new(0.04, 0, 0, 96)
        SuggestionsFrame.BackgroundTransparency = 1
        SuggestionsFrame.BorderSizePixel = 0
        SuggestionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        SuggestionsFrame.ScrollBarThickness = 6
        SuggestionsFrame.ScrollBarImageColor3 = TEMA.NeonCiano
        local ListLayout = Instance.new("UIListLayout", SuggestionsFrame)
        ListLayout.Padding = UDim.new(0, 8)
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local ControlsFrame = Instance.new("Frame", EspiaoMainFrame)
        ControlsFrame.Size = UDim2.new(0.92, 0, 0, 40)
        ControlsFrame.Position = UDim2.new(0.04, 0, 0, 304)
        ControlsFrame.BackgroundTransparency = 1
        ControlsFrame.BorderSizePixel = 0

        local PrevButton = Instance.new("TextButton", ControlsFrame)
        PrevButton.Size = UDim2.new(0.48, -6, 1, 0)
        PrevButton.Position = UDim2.new(0, 0, 0, 0)
        PrevButton.BackgroundColor3 = TEMA.BgSecundario
        PrevButton.Text = "◀ Anterior"
        PrevButton.TextColor3 = TEMA.TextoBranco
        PrevButton.Font = Enum.Font.GothamBold
        PrevButton.TextSize = 12
        PrevButton.BorderSizePixel = 0
        Instance.new("UICorner", PrevButton).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", PrevButton).Color = TEMA.NeonCiano

        local NextButton = Instance.new("TextButton", ControlsFrame)
        NextButton.Size = UDim2.new(0.48, -6, 1, 0)
        NextButton.Position = UDim2.new(0.52, 0, 0, 0)
        NextButton.BackgroundColor3 = TEMA.BgSecundario
        NextButton.Text = "Próximo ▶"
        NextButton.TextColor3 = TEMA.TextoBranco
        NextButton.Font = Enum.Font.GothamBold
        NextButton.TextSize = 12
        NextButton.BorderSizePixel = 0
        Instance.new("UICorner", NextButton).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", NextButton).Color = TEMA.NeonCiano

        local StopButton = Instance.new("TextButton", EspiaoMainFrame)
        StopButton.Size = UDim2.new(0.92, 0, 0, 36)
        StopButton.Position = UDim2.new(0.04, 0, 0, 352)
        StopButton.BackgroundColor3 = TEMA.BgSecundario
        StopButton.Text = "PAUSE"
        StopButton.TextColor3 = TEMA.NeonRosa
        StopButton.Font = Enum.Font.GothamBold
        StopButton.TextSize = 12
        StopButton.BorderSizePixel = 0
        StopButton.Visible = false
        Instance.new("UICorner", StopButton).CornerRadius = UDim.new(0, 8)
        local StopStroke = Instance.new("UIStroke", StopButton)
        StopStroke.Color = TEMA.NeonRosa
        StopStroke.Thickness = 1.5

        local ReassistirButton = Instance.new("TextButton", EspiaoMainFrame)
        ReassistirButton.Size = StopButton.Size
        ReassistirButton.Position = StopButton.Position
        ReassistirButton.BackgroundColor3 = TEMA.BgSecundario
        ReassistirButton.Text = "REASSISTIR"
        ReassistirButton.TextColor3 = TEMA.NeonCiano
        ReassistirButton.Font = Enum.Font.GothamBold
        ReassistirButton.TextSize = 12
        ReassistirButton.BorderSizePixel = 0
        ReassistirButton.Visible = false
        Instance.new("UICorner", ReassistirButton).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", ReassistirButton).Color = TEMA.NeonCiano

        -- ============================================
        -- SISTEMA DE OTIMIZAÇÃO (ON/OFF DO LOOP DE CÂMERA)
        -- ============================================
        local function DesligarLoopCamera()
            if loopCameraEspiao then
                loopCameraEspiao:Disconnect()
                loopCameraEspiao = nil
            end
        end

        local function LigarLoopCamera()
            if loopCameraEspiao then return end 

            loopCameraEspiao = RunService.RenderStepped:Connect(function()
                if ID_EXECUCAO ~= _G.VersaoAtual then 
                    DesligarLoopCamera() 
                    return 
                end
                
                if alvoAtual and isPlayerValid(alvoAtual) then
                    local char = alvoAtual.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        local head = char:FindFirstChild("Head")
                        safeSetCameraType(Enum.CameraType.Custom)
                        if hum then
                            safeSetCameraSubject(hum)
                        end
                        if head then
                            SoundService:SetListener(Enum.ListenerType.ObjectPosition, head)
                        else
                            SoundService:SetListener(Enum.ListenerType.Camera)
                        end
                    end
                elseif alvoAtual and not isPlayerValid(alvoAtual) then
                    pararEspionagem()
                end
            end)
            
            table.insert(conexoesParaLimpar, loopCameraEspiao)
        end
        -- ============================================

        -- Funções principais
        local function iniciarEspionagem(alvoPlayer)
            if not alvoPlayer or alvoPlayer == player then return end
            userPaused = false
            ultimoAlvo = alvoPlayer
            alvoAtual = alvoPlayer
            StopButton.Visible = (not isMinimized)
            ReassistirButton.Visible = false
            TitleLabel.Text = "👁️ ESPIANDO: " .. (alvoPlayer.DisplayName or alvoPlayer.Name or "Alvo")

            -- suprime restauração automática da câmera para o jogador local
            suppressLocalCameraRestore = true

            if alvoAtual and alvoAtual.Character then
                local hum = alvoAtual.Character:FindFirstChildOfClass("Humanoid")
                local head = alvoAtual.Character:FindFirstChild("Head")
                if hum then
                    safeSetCameraType(Enum.CameraType.Custom)
                    safeSetCameraSubject(hum)
                    if head then
                        SoundService:SetListener(Enum.ListenerType.ObjectPosition, head)
                    else
                        SoundService:SetListener(Enum.ListenerType.Camera)
                    end
                end
            end
            
            -- LIGA O LOOP AQUI
            LigarLoopCamera()
        end

        pararEspionagem = function() -- Função declarada como global no escopo 'do'
            -- DESLIGA O LOOP AQUI, poupando a máquina
            DesligarLoopCamera()
            
            userPaused = true
            if alvoAtual then ultimoAlvo = alvoAtual end
            alvoAtual = nil
            StopButton.Visible = false
            TitleLabel.Text = "👁️ ESPIÃO"
            ReassistirButton.Visible = (not isMinimized) and (ultimoAlvo ~= nil and isPlayerValid(ultimoAlvo))

            -- permite que a câmera volte ao jogador local quando apropriado
            suppressLocalCameraRestore = false

            -- restaura câmera para o jogador local imediatamente
            safeSetCameraType(Enum.CameraType.Custom)
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                safeSetCameraSubject(player.Character:FindFirstChildOfClass("Humanoid"))
            end
            SoundService:SetListener(Enum.ListenerType.Camera)
        end

        local function clearSuggestions()
            for _, child in pairs(SuggestionsFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
        end

        local function selectIndex(index)
            if #filteredPlayers == 0 then currentIndex = 0; return end
            if index < 1 then index = 1 end
            if index > #filteredPlayers then index = #filteredPlayers end
            if not isPlayerValid(filteredPlayers[index]) then
                local nextIdx = findNextValidIndex(index, 1)
                if nextIdx == 0 then currentIndex = 0; return else index = nextIdx end
            end
            currentIndex = index
            local p = filteredPlayers[currentIndex]
            if p and isPlayerValid(p) then iniciarEspionagem(p) end
        end

        local function atualizarLista()
            local previousTarget = alvoAtual
            clearSuggestions()
            filteredPlayers = {}
            currentIndex = 0

            local textoBusca = string.lower(SearchBox.Text or "")
            local count = 0
            local seen = {}

            local allPlayers = Players:GetPlayers()
            table.sort(allPlayers, function(a,b) return a.UserId < b.UserId end)

            for _, p in ipairs(allPlayers) do
                if p ~= player then
                    local nomeValido = string.find(string.lower(p.Name), textoBusca)
                    local displayValido = string.find(string.lower(p.DisplayName), textoBusca)
                    if textoBusca == "" or nomeValido or displayValido then
                        if not seen[p.UserId] then
                            seen[p.UserId] = true
                            count = count + 1
                            table.insert(filteredPlayers, p)

                            local BotaoPlayer = Instance.new("TextButton", SuggestionsFrame)
                            BotaoPlayer.Size = UDim2.new(1, -8, 0, 44) 
                            BotaoPlayer.BackgroundColor3 = TEMA.BgSecundario
                            BotaoPlayer.Text = (p.DisplayName or p.Name) .. " (@" .. p.Name .. ")"
                            BotaoPlayer.TextColor3 = TEMA.TextoBranco
                            BotaoPlayer.Font = Enum.Font.GothamMedium
                            BotaoPlayer.TextSize = 13
                            BotaoPlayer.TextXAlignment = Enum.TextXAlignment.Left
                            BotaoPlayer.TextYAlignment = Enum.TextYAlignment.Center
                            BotaoPlayer.TextWrapped = true
                            BotaoPlayer.TextTruncate = Enum.TextTruncate.None
                            BotaoPlayer.BorderSizePixel = 0

                            Instance.new("UICorner", BotaoPlayer).CornerRadius = UDim.new(0, 6)
                            local BtnStroke = Instance.new("UIStroke", BotaoPlayer)
                            BtnStroke.Color = Color3.fromRGB(45, 45, 55)
                            local BtnPadding = Instance.new("UIPadding", BotaoPlayer)
                            BtnPadding.PaddingLeft = UDim.new(0, 12)
                            BtnPadding.PaddingRight = UDim.new(0, 8)

                            BotaoPlayer.MouseEnter:Connect(function()
                                BtnStroke.Color = TEMA.NeonCiano
                                BotaoPlayer.TextColor3 = TEMA.NeonCiano
                            end)
                            BotaoPlayer.MouseLeave:Connect(function()
                                BtnStroke.Color = Color3.fromRGB(45, 45, 55)
                                BotaoPlayer.TextColor3 = TEMA.TextoBranco
                            end)

                            local thisIndex = #filteredPlayers
                            table.insert(conexoesParaLimpar, BotaoPlayer.MouseButton1Click:Connect(function() selectIndex(thisIndex) end))
                        end
                    end
                end
            end

            SuggestionsFrame.CanvasSize = UDim2.new(0, 0, 0, count * 52)

            if previousTarget and isPlayerValid(previousTarget) then
                for i, p in ipairs(filteredPlayers) do
                    if p == previousTarget then
                        if not userPaused then selectIndex(i) end
                        return
                    end
                end
            end

            if not userPaused and #filteredPlayers > 0 then
                local firstValid = findNextValidIndex(1, 1)
                if firstValid ~= 0 then selectIndex(firstValid) end
            end
        end

        -- Conexões do Espião
        table.insert(conexoesParaLimpar, SearchBox:GetPropertyChangedSignal("Text"):Connect(function() atualizarLista() end))

        table.insert(conexoesParaLimpar, PrevButton.MouseButton1Click:Connect(function()
            if #filteredPlayers == 0 then return end
            local start = currentIndex; if start == 0 then start = 1 end
            local newIndex = findNextValidIndex(start, -1)
            if newIndex ~= 0 then selectIndex(newIndex) end
        end))

        table.insert(conexoesParaLimpar, NextButton.MouseButton1Click:Connect(function()
            if #filteredPlayers == 0 then return end
            local start = currentIndex; if start == 0 then start = 1 end
            local newIndex = findNextValidIndex(start, 1)
            if newIndex ~= 0 then selectIndex(newIndex) end
        end))

        table.insert(conexoesParaLimpar, StopButton.MouseButton1Click:Connect(pararEspionagem))
        
        table.insert(conexoesParaLimpar, ReassistirButton.MouseButton1Click:Connect(function()
            if ultimoAlvo and isPlayerValid(ultimoAlvo) then iniciarEspionagem(ultimoAlvo) else ReassistirButton.Visible = false end
        end))

        table.insert(conexoesParaLimpar, MinimizeButton.MouseButton1Click:Connect(function()
            isMinimized = not isMinimized
            if isMinimized then
                EspiaoMainFrame.Size = UDim2.new(0, 320, 0, 48)
                SearchBox.Visible = false
                SuggestionsFrame.Visible = false
                ControlsFrame.Visible = false
                StopButton.Visible = false
                ReassistirButton.Visible = false
                MinimizeButton.Text = "+"
            else
                EspiaoMainFrame.Size = UDim2.new(0, 320, 0, 420)
                SearchBox.Visible = true
                SuggestionsFrame.Visible = true
                ControlsFrame.Visible = true
                StopButton.Visible = (alvoAtual ~= nil) and (not isMinimized)
                ReassistirButton.Visible = (userPaused and ultimoAlvo ~= nil and isPlayerValid(ultimoAlvo) and not isMinimized)
                MinimizeButton.Text = "—"
            end
        end))

        table.insert(conexoesParaLimpar, Players.PlayerAdded:Connect(function() atualizarLista() end))
        table.insert(conexoesParaLimpar, Players.PlayerRemoving:Connect(function()
            if ultimoAlvo and not isPlayerValid(ultimoAlvo) then ultimoAlvo = nil; ReassistirButton.Visible = false end
            if alvoAtual and (not isPlayerValid(alvoAtual)) then pararEspionagem() end
            atualizarLista()
        end))

        -- Quando o jogador renasce: reaplica subject do alvo imediatamente para evitar qualquer troca momentânea
        table.insert(conexoesParaLimpar, player.CharacterAdded:Connect(function()
            if alvoAtual and isPlayerValid(alvoAtual) then
                RunService.Heartbeat:Wait()
                if alvoAtual and alvoAtual.Character then
                    local hum = alvoAtual.Character:FindFirstChildOfClass("Humanoid")
                    local head = alvoAtual.Character:FindFirstChild("Head")
                    if hum then
                        safeSetCameraType(Enum.CameraType.Custom)
                        safeSetCameraSubject(hum)
                        if head then SoundService:SetListener(Enum.ListenerType.ObjectPosition, head) end
                        suppressLocalCameraRestore = true
                    end
                end
            else
                -- se não estamos espionando e não suprimimos, restaura câmera local
                if not suppressLocalCameraRestore then
                    RunService.Heartbeat:Wait()
                    if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                        safeSetCameraType(Enum.CameraType.Custom)
                        safeSetCameraSubject(player.Character:FindFirstChildOfClass("Humanoid"))
                        SoundService:SetListener(Enum.ListenerType.Camera)
                    end
                end
            end
        end))

        -- Atualização periódica para DisplayName
        local timer = 0
        table.insert(conexoesParaLimpar, RunService.Heartbeat:Connect(function(dt)
            if ID_EXECUCAO ~= _G.VersaoAtual then return end
            timer = timer + dt
            if timer >= 5 then
                timer = 0
                if not SearchBox:IsFocused() then atualizarLista() end
            end
        end))

        -- Drag pela TitleLabel
        local dragging = false
        local dragStart = Vector2.new(0, 0)
        local startPos = EspiaoMainFrame.Position
        local dragInput = nil

        local function updateDrag(input)
            if not dragging or not dragStart or not startPos then return end
            local delta = input.Position - dragStart
            EspiaoMainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        table.insert(conexoesParaLimpar, TitleLabel.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = EspiaoMainFrame.Position
                dragInput = input
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        dragInput = nil
                    end
                end)
            end
        end))

        table.insert(conexoesParaLimpar, TitleLabel.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end))

        table.insert(conexoesParaLimpar, UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then updateDrag(input) end
        end))

        -- Inicializa a lista e Lógica do Botão do Painel
        atualizarLista()
        
        local EspiaoPainelVisivel = false
        table.insert(conexoesParaLimpar, btnESPIAO.MouseButton1Click:Connect(function()
            EspiaoPainelVisivel = not EspiaoPainelVisivel
            EspiaoMainFrame.Visible = EspiaoPainelVisivel
            btnESPIAO.BackgroundColor3 = EspiaoPainelVisivel and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(10, 10, 12)
            btnESPIAO.TextColor3 = EspiaoPainelVisivel and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(0, 255, 255)
        end))
    end
    -- [FIM DA ADIÇÃO: SISTEMA ESPIÃO]

    local _, currentHum = ObterComponentes()
    if currentHum then CarregarAnimacoes(currentHum) end
    updateList()
end

task.spawn(InicializarPainel)
---
---
---
------[INICIO DE AÇÕES SEM PAINEL INTERNO]

---[INICIO DA AÇÃO SUPER REJOIN]

local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlaceId = game.PlaceId
local JobId = game.JobId

-- Função que faz o Rejoin
local function forceRejoin()
    -- Desativa a tela de pausa para limpar a visão antes do teleporte
    pcall(function()
        game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(false)
    end)

    if JobId ~= "" and #JobId > 0 then
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    else
        TeleportService:Teleport(PlaceId, LocalPlayer)
    end
end

-- Monitora as teclas pressionadas
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Evita que o atalho seja ativado sem querer se você estiver digitando no chat
    if gameProcessed then return end

    -- Verifica se o Control (esquerdo ou direito) está sendo segurado
    local ctrlPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    
    -- Verifica se os números 0, 9 e 8 estão sendo segurados (suporta tanto os números de cima quanto os do teclado numérico/numpad)
    local zeroPressed = UserInputService:IsKeyDown(Enum.KeyCode.Zero) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadZero)
    local ninePressed = UserInputService:IsKeyDown(Enum.KeyCode.Nine) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadNine)
    local eightPressed = UserInputService:IsKeyDown(Enum.KeyCode.Eight) or UserInputService:IsKeyDown(Enum.KeyCode.KeypadEight)

    -- Se as 4 teclas estiverem pressionadas simultaneamente, dispara o Rejoin
    if ctrlPressed and zeroPressed and ninePressed and eightPressed then
        forceRejoin()
    end
end)

---[FIM DA AÇÃO SUPER REJOIN]

---[INICIO DA AÇÃO DE CRONÔMETRO]
-- Serviços Necessários
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Prevenção de duplicatas
local guiName = "CronometroAvancadoGui"
if CoreGui:FindFirstChild(guiName) then
    CoreGui[guiName]:Destroy()
elseif Players.LocalPlayer.PlayerGui:FindFirstChild(guiName) then
    Players.LocalPlayer.PlayerGui[guiName]:Destroy()
end

-- Determinar onde colocar a GUI
local parentGui = pcall(function() return CoreGui.Name end) and CoreGui or Players.LocalPlayer.PlayerGui

-- Variáveis do Cronômetro
local isRunning = false
local startTime = 0
local elapsedTime = 0
local connection = nil
local marksCount = 0
local isMinimized = true -- INICIA FECHADO

-------------------------------------------------------------------------------
-- CRIAÇÃO DA INTERFACE VISUAL
-------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Painel Principal Móvel
local MainFrame = Instance.new("Frame")
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- Ponto central para animação de encolher/crescer
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 0, 0, 0) -- Tamanho inicial 0 (fechado)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false -- Inicia invisível
MainFrame.ClipsDescendants = true -- Esconde os itens internos enquanto encolhe
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Cronômetro Profissional"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Display de Tempo
local TimeDisplay = Instance.new("TextLabel")
TimeDisplay.Size = UDim2.new(1, -40, 0, 60)
TimeDisplay.Position = UDim2.new(0, 20, 0, 45)
TimeDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TimeDisplay.BackgroundTransparency = 0.3
TimeDisplay.Text = "00:00:00:00:0"
TimeDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeDisplay.Font = Enum.Font.Code
TimeDisplay.TextSize = 28
TimeDisplay.Parent = MainFrame

local TimeCorner = Instance.new("UICorner")
TimeCorner.CornerRadius = UDim.new(0, 8)
TimeCorner.Parent = TimeDisplay

-- Legenda do Tempo
local TimeLegend = Instance.new("TextLabel")
TimeLegend.Size = UDim2.new(1, -40, 0, 20)
TimeLegend.Position = UDim2.new(0, 20, 0, 110)
TimeLegend.BackgroundTransparency = 1
TimeLegend.Text = "HR   :   MIN   :   SEG   :   CEN   :   MIL"
TimeLegend.TextColor3 = Color3.fromRGB(150, 150, 150)
TimeLegend.Font = Enum.Font.GothamSemibold
TimeLegend.TextSize = 11
TimeLegend.Parent = MainFrame

-- Área de Botões
local BtnStartPause = Instance.new("TextButton")
BtnStartPause.Size = UDim2.new(0, 150, 0, 40)
BtnStartPause.Position = UDim2.new(0, 20, 0, 140)
BtnStartPause.BackgroundColor3 = Color3.fromRGB(46, 204, 113) 
BtnStartPause.Text = "INICIAR"
BtnStartPause.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnStartPause.Font = Enum.Font.GothamBold
BtnStartPause.TextSize = 13
BtnStartPause.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 6)
BtnCorner1.Parent = BtnStartPause

local BtnReset = Instance.new("TextButton")
BtnReset.Size = UDim2.new(0, 150, 0, 40)
BtnReset.Position = UDim2.new(0, 180, 0, 140)
BtnReset.BackgroundColor3 = Color3.fromRGB(90, 90, 95)
BtnReset.Text = "REINICIAR"
BtnReset.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnReset.Font = Enum.Font.GothamBold
BtnReset.TextSize = 13
BtnReset.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 6)
BtnCorner2.Parent = BtnReset

local BtnMark = Instance.new("TextButton")
BtnMark.Size = UDim2.new(1, -40, 0, 40)
BtnMark.Position = UDim2.new(0, 20, 0, 190)
BtnMark.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
BtnMark.Text = "MARCAR TEMPO"
BtnMark.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnMark.Font = Enum.Font.GothamBold
BtnMark.TextSize = 13
BtnMark.Parent = MainFrame

local BtnCorner3 = Instance.new("UICorner")
BtnCorner3.CornerRadius = UDim.new(0, 6)
BtnCorner3.Parent = BtnMark

-- Área de Marcações (Laps)
local MarksScroll = Instance.new("ScrollingFrame")
MarksScroll.Size = UDim2.new(1, -40, 0, 140)
MarksScroll.Position = UDim2.new(0, 20, 0, 245)
MarksScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MarksScroll.BackgroundTransparency = 0.5
MarksScroll.ScrollBarThickness = 4
MarksScroll.BorderSizePixel = 0
MarksScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MarksScroll.Parent = MainFrame

local MarksLayout = Instance.new("UIListLayout")
MarksLayout.Padding = UDim.new(0, 6)
MarksLayout.SortOrder = Enum.SortOrder.LayoutOrder
MarksLayout.Parent = MarksScroll

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = MarksScroll

-------------------------------------------------------------------------------
-- LÓGICA E FUNÇÕES
-------------------------------------------------------------------------------

-- Função para formatar o tempo
local function formatTime(timeInSeconds)
    local totalMs = math.floor(timeInSeconds * 1000)
    local hours = math.floor(totalMs / 3600000)
    local mins = math.floor((totalMs % 3600000) / 60000)
    local secs = math.floor((totalMs % 60000) / 1000)
    local centi = math.floor((totalMs % 1000) / 10)
    local mili = totalMs % 10
    
    return string.format("%02d:%02d:%02d:%02d:%01d", hours, mins, secs, centi, mili)
end

-- Atualizar Display
local function updateDisplay()
    local currentTime = elapsedTime
    if isRunning then
        currentTime = currentTime + (os.clock() - startTime)
    end
    TimeDisplay.Text = formatTime(currentTime)
end

-- Feedback Tátil (Animação ao clicar)
local function applyTactileFeedback(button)
    local originalSize = button.Size
    local clickSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset - 2, originalSize.Y.Scale, originalSize.Y.Offset - 2)
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Size = clickSize}):Play()
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = originalSize}):Play()
        end
    end)
end

applyTactileFeedback(BtnStartPause)
applyTactileFeedback(BtnReset)
applyTactileFeedback(BtnMark)

-- Sistema de Arrastar (Painel Móvel)
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- FUNÇÃO DE MINIMIZAR / MOSTRAR (Ctrl + Shift + M)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.M then
        local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        local shiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        
        if ctrlDown and shiftDown then
            isMinimized = not isMinimized
            
            if isMinimized then
                -- Ocultar (Encolher até sumir)
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
                local tween = TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
                tween:Play()
                
                -- Torna invisível após a animação terminar para não bugar cliques na tela
                tween.Completed:Wait()
                if isMinimized then
                    MainFrame.Visible = false
                end
            else
                -- Mostrar (Crescer)
                MainFrame.Visible = true
                local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 350, 0, 400)}):Play()
            end
        end
    end
end)

-- Lógica dos Botões do Cronômetro
BtnStartPause.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    
    if isRunning then
        startTime = os.clock()
        BtnStartPause.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        BtnStartPause.Text = "PAUSAR"
        
        connection = RunService.RenderStepped:Connect(function()
            updateDisplay()
        end)
    else
        if connection then connection:Disconnect() end
        elapsedTime = elapsedTime + (os.clock() - startTime)
        BtnStartPause.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        BtnStartPause.Text = "RETOMAR"
        updateDisplay()
    end
end)

BtnReset.MouseButton1Click:Connect(function()
    isRunning = false
    if connection then connection:Disconnect() end
    elapsedTime = 0
    startTime = 0
    
    BtnStartPause.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    BtnStartPause.Text = "INICIAR"
    updateDisplay()
    
    for _, child in pairs(MarksScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    marksCount = 0
    MarksScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
end)

BtnMark.MouseButton1Click:Connect(function()
    local currentTime = elapsedTime
    if isRunning then
        currentTime = currentTime + (os.clock() - startTime)
    end
    
    marksCount = marksCount + 1
    
    local MarkLabel = Instance.new("TextLabel")
    MarkLabel.Size = UDim2.new(1, 0, 0, 28)
    MarkLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    MarkLabel.BackgroundTransparency = 0.2
    MarkLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    MarkLabel.Font = Enum.Font.Code
    MarkLabel.TextSize = 14
    MarkLabel.Text = string.format("  Marca %02d   -   %s", marksCount, formatTime(currentTime))
    MarkLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local MarkCorner = Instance.new("UICorner")
    MarkCorner.CornerRadius = UDim.new(0, 4)
    MarkCorner.Parent = MarkLabel
    
    MarkLabel.Parent = MarksScroll
    MarksScroll.CanvasSize = UDim2.new(0, 0, 0, marksCount * 34)
    MarksScroll.CanvasPosition = Vector2.new(0, MarksScroll.CanvasSize.Y.Offset)
end)

-- Inicialização
updateDisplay()
---[FIM DA AÇÃO DE CRONÔMETRO]

---[INICIO DA AÇÃO RESPAWN]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local customSpawnCFrame = nil

-- Função para salvar o local de spawn
local function setCustomSpawn()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        customSpawnCFrame = character.HumanoidRootPart.CFrame
        
        StarterGui:SetCore("SendNotification", {
            Title = "Spawn Salvo",
            Text = "Você renascerá neste exato local.",
            Duration = 3
        })
    end
end

-- Detecta as combinações de teclas
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- COMBINAÇÃO 1: Apenas Salvar Spawn (Ctrl + F + G)
    if input.KeyCode == Enum.KeyCode.G then
        local isCtrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        local isFDown = UserInputService:IsKeyDown(Enum.KeyCode.F)

        if isCtrlDown and isFDown then
            setCustomSpawn()
        end
    end

    -- COMBINAÇÃO 2: Salvar Spawn e Resetar (Ctrl + Shift + R)
    if input.KeyCode == Enum.KeyCode.R then
        local isCtrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        local isShiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

        if isCtrlDown and isShiftDown then
            -- Primeiro passo: Salva a posição exata atual
            setCustomSpawn()
            
            -- Segundo passo: Força o reset zerando a vida
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end
    end
end)

-- Toda vez que o personagem renascer, teleporta para o local salvo
player.CharacterAdded:Connect(function(character)
    if customSpawnCFrame then
        local hrp = character:WaitForChild("HumanoidRootPart", 5)
        
        if hrp then
            task.wait(0.15) 
            hrp.CFrame = customSpawnCFrame
        end
    end
end)

---[FIM DA AÇÃO RESPAWN]

----------------INCLUIR SCRIPT DO CHOCOLATE----------------

-----------------------------------------------------------


---[INICIO DA FUNÇÃO DE STAFF DE CARGOS E ID]
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

-- ==========================================
-- 1. SISTEMA ANTI-FALHA PARA CRIAR A INTERFACE
-- ==========================================
local uiParent
local success = pcall(function() uiParent = game:GetService("CoreGui") end)
if not success or not uiParent then
    uiParent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

if uiParent:FindFirstChild("PainelStaffSupremo") then
    uiParent.PainelStaffSupremo:Destroy()
end

-- ==========================================
-- 2. CONFIGURAÇÕES AUTOMÁTICAS E MANUAIS
-- ==========================================
local GameGroupId = 0
if game.CreatorType == Enum.CreatorType.Group then
    GameGroupId = game.CreatorId
end

-- ID da Gamepass VIP (Substitua 0 pelo ID real se possuir)
local ID_GAMEPASS_VIP = 0 

-- ==========================================
-- 3. CRIANDO A INTERFACE PRINCIPAL
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PainelStaffSupremo"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = uiParent

local MainFrame = Instance.new("Frame")
MainFrame.Visible = false
MainFrame.Size = UDim2.new(0, 900, 0, 500)
MainFrame.Position = UDim2.new(0.5, -450, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2 -- Deixado um pouco mais opaco para leitura
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Permite mover o painel clicando no corpo/topo
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -150, 0, 50)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Descori Cargos e ID"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 120, 0, 35)
RefreshBtn.Position = UDim2.new(1, -140, 0, 7)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
RefreshBtn.Text = "Atualizar Lista"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 14
RefreshBtn.Parent = MainFrame
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 5)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -40, 1, -70)
Scroll.Position = UDim2.new(0, 20, 0, 50)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 6
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
end)

-- ==========================================
-- 3.1. SISTEMA DE REDIMENSIONAMENTO NA BORDA (RESIZE GRIP)
-- ==========================================
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Size = UDim2.new(0, 20, 0, 20)
ResizeGrip.Position = UDim2.new(1, -20, 1, -20)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Text = "↘️"
ResizeGrip.TextColor3 = Color3.fromRGB(150, 150, 150)
ResizeGrip.TextSize = 18
ResizeGrip.Parent = MainFrame

local isResizing = false
local dragStartPos = nil
local startSize = nil

ResizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        dragStartPos = input.Position
        startSize = MainFrame.AbsoluteSize
    end
end)

UIS.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        -- Limites de tamanho (Mínimo 600x300, Máximo 1500x900)
        local newWidth = math.clamp(startSize.X + delta.X, 600, 1500)
        local newHeight = math.clamp(startSize.Y + delta.Y, 300, 900)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false
    end
end)

-- ==========================================
-- 4. VERIFICAÇÃO AVANÇADA DE CARGOS
-- ==========================================
local function IdentificarCargo(player)
    local nomeCargo = "Jogador"
    local corCargo = Color3.fromRGB(150, 150, 150)

    pcall(function()
        -- 1. Dono do Jogo (Usuário Físico)
        if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
            nomeCargo, corCargo = "Criador do Jogo", Color3.fromRGB(255, 0, 127) -- Rosa Choque
            return
        end

        -- 2. Youtubers / Star Creators Oficiais do Roblox
        if player:IsInGroup(4199740) then
            nomeCargo, corCargo = "Roblox Star Creator", Color3.fromRGB(255, 170, 0)
            return
        end

        -- 3. Varredura Profunda no Grupo do Jogo
        if GameGroupId ~= 0 then
            local rank = player:GetRankInGroup(GameGroupId)
            if rank > 0 then
                local cargoNoGrupo = player:GetRoleInGroup(GameGroupId)
                local cargoLower = string.lower(cargoNoGrupo)
                
                -- Nível Direção / Dono
                if rank >= 250 or string.find(cargoLower, "dono") or string.find(cargoLower, "owner") or string.find(cargoLower, "diretor") or string.find(cargoLower, "founder") then
                    nomeCargo, corCargo = "Diretoria: " .. cargoNoGrupo, Color3.fromRGB(255, 0, 127)
                    return
                -- Nível Desenvolvimento
                elseif string.find(cargoLower, "dev") or string.find(cargoLower, "programador") or string.find(cargoLower, "scripter") or string.find(cargoLower, "builder") or string.find(cargoLower, "modeler") then
                    nomeCargo, corCargo = "Developer: " .. cargoNoGrupo, Color3.fromRGB(170, 85, 255) -- Roxo
                    return
                -- Nível Administração
                elseif rank >= 200 or string.find(cargoLower, "admin") or string.find(cargoLower, "gerente") or string.find(cargoLower, "manager") or string.find(cargoLower, "head") then
                    nomeCargo, corCargo = "Administração: " .. cargoNoGrupo, Color3.fromRGB(255, 50, 50) -- Vermelho
                    return
                -- Nível Moderação
                elseif rank >= 100 or string.find(cargoLower, "mod") or string.find(cargoLower, "supervis") or string.find(cargoLower, "coord") then
                    nomeCargo, corCargo = "Moderação: " .. cargoNoGrupo, Color3.fromRGB(50, 255, 100) -- Verde Claro
                    return
                -- Nível Suporte / Ajudante
                elseif string.find(cargoLower, "suporte") or string.find(cargoLower, "ajudante") or string.find(cargoLower, "helper") or string.find(cargoLower, "support") then
                    nomeCargo, corCargo = "Suporte: " .. cargoNoGrupo, Color3.fromRGB(85, 255, 255) -- Ciano
                    return
                -- Nível Marketing / Influencer
                elseif string.find(cargoLower, "market") or string.find(cargoLower, "youtube") or string.find(cargoLower, "stream") or string.find(cargoLower, "influenc") or string.find(cargoLower, "tiktok") then
                    nomeCargo, corCargo = "Midia: " .. cargoNoGrupo, Color3.fromRGB(255, 170, 0) -- Laranja
                    return
                -- Nível Qualidade / Tester
                elseif string.find(cargoLower, "test") or string.find(cargoLower, "qa") then
                    nomeCargo, corCargo = "QA Tester", Color3.fromRGB(255, 120, 200) -- Rosa Claro
                    return
                -- Nível VIP (In-Group)
                elseif string.find(cargoLower, "vip") or string.find(cargoLower, "premium") or string.find(cargoLower, "doador") or string.find(cargoLower, "donator") then
                    nomeCargo, corCargo = "VIP do Grupo", Color3.fromRGB(255, 215, 0) -- Dourado
                    return
                -- Qualquer outro membro da Staff não mapeado
                elseif rank >= 10 then
                    nomeCargo, corCargo = "Staff: " .. cargoNoGrupo, Color3.fromRGB(200, 200, 50) -- Amarelo Queimado
                    return
                end
            end
        end

        -- 4. Verificação de Gamepass VIP
        if ID_GAMEPASS_VIP ~= 0 then
            local hasVIPPass = false
            pcall(function() 
                hasVIPPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, ID_GAMEPASS_VIP) 
            end)
            if hasVIPPass then
                nomeCargo, corCargo = "VIP (Gamepass)", Color3.fromRGB(255, 215, 0)
                return
            end
        end

        -- 5. Verificação de Roblox Premium
        if player.MembershipType == Enum.MembershipType.Premium then
            nomeCargo, corCargo = "Jogador Premium", Color3.fromRGB(200, 200, 220)
            return
        end
    end)
    
    return nomeCargo, corCargo
end

-- ==========================================
-- 5. FUNÇÃO PARA PREENCHER A INTERFACE
-- ==========================================
local function AtualizarLista()
    for _, item in pairs(Scroll:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end

    for _, player in pairs(Players:GetPlayers()) do
        local Linha = Instance.new("Frame")
        Linha.Size = UDim2.new(1, -10, 0, 40)
        Linha.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Linha.BackgroundTransparency = 0.5
        Linha.Parent = Scroll
        Instance.new("UICorner", Linha).CornerRadius = UDim.new(0, 6)

        -- Nome de Exibição (DisplayName)
        local txtDisplay = Instance.new("TextLabel")
        txtDisplay.Size = UDim2.new(0, 230, 1, 0)
        txtDisplay.Position = UDim2.new(0, 15, 0, 0)
        txtDisplay.BackgroundTransparency = 1
        txtDisplay.Text = player.DisplayName
        txtDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
        txtDisplay.Font = Enum.Font.GothamBold
        txtDisplay.TextSize = 15
        txtDisplay.TextXAlignment = Enum.TextXAlignment.Left
        txtDisplay.TextTruncate = Enum.TextTruncate.AtEnd 
        txtDisplay.Parent = Linha

        -- Nome de Usuário (Username)
        local txtUser = Instance.new("TextLabel")
        txtUser.Size = UDim2.new(0, 200, 1, 0)
        txtUser.Position = UDim2.new(0, 260, 0, 0)
        txtUser.BackgroundTransparency = 1
        txtUser.Text = "@" .. player.Name
        txtUser.TextColor3 = Color3.fromRGB(180, 180, 180)
        txtUser.Font = Enum.Font.Gotham
        txtUser.TextSize = 13
        txtUser.TextXAlignment = Enum.TextXAlignment.Left
        txtUser.TextTruncate = Enum.TextTruncate.AtEnd
        txtUser.Parent = Linha

        -- Cargo do Jogador
        local txtCargo = Instance.new("TextLabel")
        txtCargo.Size = UDim2.new(0, 310, 1, 0)
        txtCargo.Position = UDim2.new(0, 475, 0, 0)
        txtCargo.BackgroundTransparency = 1
        txtCargo.Text = "Verificando..."
        txtCargo.TextColor3 = Color3.fromRGB(150, 150, 150)
        txtCargo.Font = Enum.Font.GothamBold
        txtCargo.TextSize = 14
        txtCargo.TextXAlignment = Enum.TextXAlignment.Left
        txtCargo.TextTruncate = Enum.TextTruncate.AtEnd
        txtCargo.Parent = Linha

        -- Leitura Assíncrona para não travar o jogo
        task.spawn(function()
            local cNome, cCor = IdentificarCargo(player)
            if txtCargo.Parent then
                txtCargo.Text = cNome
                txtCargo.TextColor3 = cCor
            end
        end)

        -- Botão de Copiar ID 
        local btnCopy = Instance.new("TextButton")
        btnCopy.Size = UDim2.new(0, 80, 0, 26)
        btnCopy.Position = UDim2.new(1, -95, 0.5, -13)
        btnCopy.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        btnCopy.Text = "Copiar ID"
        btnCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnCopy.Font = Enum.Font.GothamBold
        btnCopy.TextSize = 12
        btnCopy.Parent = Linha
        Instance.new("UICorner", btnCopy).CornerRadius = UDim.new(0, 4)

        btnCopy.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(tostring(player.UserId))
                    btnCopy.Text = "Copiado!"
                    btnCopy.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
                    task.wait(1.5)
                    if btnCopy.Parent then
                        btnCopy.Text = "Copiar ID"
                        btnCopy.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                    end
                end
            end)
        end)
    end
end

RefreshBtn.MouseButton1Click:Connect(AtualizarLista)

-- ==========================================
-- 6. SISTEMA DE OCULTAR, MOSTRAR E FEEDBACK
-- ==========================================

-- Apenas UMA definição da função de feedback
local function FeedbackAtualizar(botao)
    local corOriginal = botao.BackgroundColor3
    local textoOriginal = botao.Text
    
    botao.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Cor de processamento
    botao.Text = "..."
    
    task.wait(0.4) 
    
    botao.BackgroundColor3 = corOriginal
    botao.Text = textoOriginal
end

-- Conexão do clique no botão
RefreshBtn.MouseButton1Click:Connect(function()
    spawn(function() FeedbackAtualizar(RefreshBtn) end)
    AtualizarLista()
end)

-- Conexão do atalho CTRL + K
UIS.InputBegan:Connect(function(input, digitando)
    if digitando then return end 
    if input.KeyCode == Enum.KeyCode.K and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            spawn(function() FeedbackAtualizar(RefreshBtn) end)
            AtualizarLista()
        end
    end
end)

-- Execução inicial
AtualizarLista()
---[FIM DA FUNÇÃO DE STAFF DE CARGOS E ID]

---[INICIO DA FUNÇÃO DE ZOOM]
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local userGameSettings = UserSettings():GetService("UserGameSettings")

-- ==========================================
-- ⚙️ CONFIGURAÇÕES PRINCIPAIS
-- ==========================================
local normalFOV = 70
local sniperFOV = 5 -- Zoom forte da mira
local aimSpeed = 0.05 -- Velocidade que o zoom abre

-- 🎯 VELOCIDADE DO "AIMBOT" (Precisão)
-- Aqui você controla a lentidão ao segurar o botão.
-- 0.05 significa que a velocidade cai para 5% do normal. 
local precisionMultiplier = 0.05 
-- ==========================================

local isAiming = false
local baseSensitivity = userGameSettings.MouseSensitivity

-- Função para aplicar o Zoom
local function setFOV(targetFOV)
    local tweenInfo = TweenInfo.new(aimSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(camera, tweenInfo, {FieldOfView = targetFOV}):Play()
end

-- ==========================================
-- 🖱️ QUANDO APERTA UM BOTÃO
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local isRightClick = (input.UserInputType == Enum.UserInputType.MouseButton2)
    local isAlt = (input.KeyCode == Enum.KeyCode.LeftAlt)
    
    local holdingAlt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
    local holdingRightClick = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    -- 1. LIGAR/DESLIGAR A MIRA (Pressionando Alt + Botão Direito juntos)
    if (isRightClick and holdingAlt) or (isAlt and holdingRightClick) then
        isAiming = not isAiming 
        
        if isAiming then
            -- Atualiza a sensibilidade base e puxa o zoom
            baseSensitivity = userGameSettings.MouseSensitivity
            setFOV(sniperFOV)
            
            -- Como ele acabou de ativar segurando os dois botões, já aplicamos a lentidão
            userGameSettings.MouseSensitivity = baseSensitivity * precisionMultiplier
        else
            -- Desliga o zoom e restaura a velocidade normal
            setFOV(normalFOV)
            userGameSettings.MouseSensitivity = baseSensitivity
        end
        return -- Para a execução aqui para não dar conflito com a lógica abaixo
    end

    -- 2. MODO "AIMBOT" (Apenas segura o botão direito com a mira JÁ ligada)
    if isAiming and isRightClick and not holdingAlt then
        -- Aplica a lentidão para focar no alvo
        userGameSettings.MouseSensitivity = baseSensitivity * precisionMultiplier
    end
end)

-- ==========================================
-- 🖱️ QUANDO SOLTA UM BOTÃO
-- ==========================================
UserInputService.InputEnded:Connect(function(input, gameProcessed)
    local isRightClick = (input.UserInputType == Enum.UserInputType.MouseButton2)
    
    -- 3. SOLTOU O BOTÃO DIREITO
    if isAiming and isRightClick then
        -- A mira continua aberta (Zoom in), mas a velocidade da câmera volta ao normal 
        -- para você conseguir virar rápido e achar outro alvo
        userGameSettings.MouseSensitivity = baseSensitivity
    end
end)
---[FIM DA FUNÇÃO DE ZOOM]

---[INICIO DA FUNÇÃO ANT GAMEPLAY PAUSED E ANT AFK]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- 1. Ocultar a tela de "Gameplay Paused" do Roblox
pcall(function()
    -- Desativa a UI padrão que aparece na tela quando o jogo pausa para carregar o mapa
    GuiService:SetGameplayPausedNotificationEnabled(false)
end)

-- 2. Sistema Anti-AFK
LocalPlayer.Idled:Connect(function()
    -- Toda vez que o jogo detectar inatividade, ele simulará um clique do botão direito
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Notificação no console (F9) para confirmar que injetou
print("Bypass de Gameplay Paused e Anti-AFK ativados com sucesso!")

---[FIM DA FUNÇÃO ANT GAMEPLAY PAUSED E ANT AFK]
