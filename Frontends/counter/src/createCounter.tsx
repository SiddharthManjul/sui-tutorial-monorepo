import { Button, Container } from "@radix-ui/themes";
import { ClipLoader } from "react-spinners";

import { Transaction } from "@mysten/sui/transactions";
import { useSignAndExecuteTransaction, useSuiClient } from "@mysten/dapp-kit";
import { useNetworkVariable } from "./networkConfig";

export function CreateCounter({
  onCreated,
}: {
  onCreated: (id: string) => void;
}) {
  const counterPackageId = useNetworkVariable("counterPackageId");
  const suiClient = useSuiClient();
  const {
    mutate: signAndExecute,
    isSuccess,
    isPending,
  } = useSignAndExecuteTransaction();

  function create() {
    const tx = new Transaction();
    tx.moveCall({
      target: `${counterPackageId}::counter::create`,
    });

    signAndExecute(
      {
        transaction: tx,
      },
      {
        onSuccess: async ({ digest }) => {
          const { effects } = await suiClient.waitForTransaction({
            digest: digest,
            options: {
              showEffects: true,
            },
          });
          onCreated(effects?.created?.[0]?.reference?.objectId!);
        },
      },
    );
  }

  return (
    <Container>
  		<Button
  			size="3"
  			onClick={() => {
  				create();
  			}}
  			disabled={isSuccess || isPending}
  		>
  			{isSuccess || isPending ? <ClipLoader size={20} /> : "Create Counter"}
  		</Button>
  	</Container>
  );
}
